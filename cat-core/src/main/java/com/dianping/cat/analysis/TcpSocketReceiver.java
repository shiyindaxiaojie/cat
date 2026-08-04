/*
 * Copyright (c) 2011-2018, Meituan Dianping. All Rights Reserved.
 *
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.dianping.cat.analysis;

import com.dianping.cat.CatConstants;
import com.dianping.cat.config.server.ServerConfigManager;
import com.dianping.cat.message.CodecHandler;
import com.dianping.cat.message.io.ClientMessageEncoder;
import com.dianping.cat.message.spi.internal.DefaultMessageTree;
import com.dianping.cat.statistic.ServerStatisticManager;
import io.netty.bootstrap.ServerBootstrap;
import io.netty.buffer.ByteBuf;
import io.netty.buffer.PooledByteBufAllocator;
import io.netty.channel.*;
import io.netty.channel.epoll.EpollEventLoopGroup;
import io.netty.channel.epoll.EpollServerSocketChannel;
import io.netty.channel.nio.NioEventLoopGroup;
import io.netty.channel.socket.SocketChannel;
import io.netty.channel.socket.nio.NioServerSocketChannel;
import io.netty.handler.codec.ByteToMessageDecoder;
import io.netty.util.ReferenceCountUtil;
import org.codehaus.plexus.logging.LogEnabled;
import org.codehaus.plexus.logging.Logger;
import org.unidal.lookup.annotation.Inject;
import org.unidal.lookup.annotation.Named;

import java.util.List;

@Named(type = TcpSocketReceiver.class)
public final class TcpSocketReceiver implements LogEnabled {

	@Inject
	protected ServerConfigManager m_serverConfigManager;

	@Inject
	private MessageHandler m_handler;

	@Inject
	private ServerStatisticManager m_serverStateManager;

	private ChannelFuture m_future;

	private EventLoopGroup m_bossGroup;

	private EventLoopGroup m_workerGroup;

	private Logger m_logger;

	private int m_maxMessageSize;

	private boolean m_destroyed;

	private final int m_port = 2280; // default port number from phone, C:2, A:2, T:8

	public void destroy() {
		destroy(m_serverConfigManager.getGracefulShutdownTimeoutSeconds() * 1000L);
	}

	public synchronized void destroy(long timeoutMillis) {
		if (m_destroyed) {
			return;
		}
		m_destroyed = true;
		long deadline = System.currentTimeMillis() + Math.max(0, timeoutMillis);

		try {
			m_logger.info("start shutdown socket, port " + m_port);
			if (m_future != null) {
				m_future.channel().close().syncUninterruptibly();
			}
			if (m_bossGroup != null) {
				long remaining = Math.max(0, deadline - System.currentTimeMillis());

				m_bossGroup.shutdownGracefully(0, remaining, java.util.concurrent.TimeUnit.MILLISECONDS);
				m_bossGroup.terminationFuture().awaitUninterruptibly(remaining);
			}
			if (m_workerGroup != null) {
				long remaining = Math.max(0, deadline - System.currentTimeMillis());

				m_workerGroup.shutdownGracefully(0, remaining, java.util.concurrent.TimeUnit.MILLISECONDS);
				m_workerGroup.terminationFuture().awaitUninterruptibly(remaining);
			}
			m_logger.info("shutdown socket success");
		} catch (Exception e) {
			m_logger.warn(e.getMessage(), e);
		}
	}

	@Override
	public void enableLogging(Logger logger) {
		m_logger = logger;
	}

	protected boolean getOSMatches(String osNamePrefix) {
		String os = System.getProperty("os.name");

		if (os == null) {
			return false;
		}
		return os.startsWith(osNamePrefix);
	}

	public void init() {
		try {
			startServer(m_port);
		} catch (Exception e) {
			m_logger.error(e.getMessage(), e);
		}
	}

	public synchronized void startServer(int port) throws InterruptedException {
		boolean linux = getOSMatches("Linux") || getOSMatches("LINUX");
		int bossThreads = m_serverConfigManager.getNettyBossThreads();
		int workerThreads = m_serverConfigManager.getNettyWorkerThreads();
		m_maxMessageSize = m_serverConfigManager.getMaxMessageSize();
		ServerBootstrap bootstrap = new ServerBootstrap();

		m_bossGroup = linux ? new EpollEventLoopGroup(bossThreads) : new NioEventLoopGroup(bossThreads);
		m_workerGroup = linux ? new EpollEventLoopGroup(workerThreads) : new NioEventLoopGroup(workerThreads);
		bootstrap.group(m_bossGroup, m_workerGroup);
		bootstrap.channel(linux ? EpollServerSocketChannel.class : NioServerSocketChannel.class);

		bootstrap.childHandler(new ChannelInitializer<SocketChannel>() {
			@Override
			protected void initChannel(SocketChannel ch) throws Exception {
				ChannelPipeline pipeline = ch.pipeline();

				pipeline.addLast("decode", new MessageDecoder(m_maxMessageSize));
				pipeline.addLast("encode", new ClientMessageEncoder());
			}
		});

		bootstrap.childOption(ChannelOption.SO_REUSEADDR, true);
		bootstrap.childOption(ChannelOption.TCP_NODELAY, true);
		bootstrap.childOption(ChannelOption.SO_KEEPALIVE, true);
		bootstrap.childOption(ChannelOption.ALLOCATOR, PooledByteBufAllocator.DEFAULT);

		try {
			m_future = bootstrap.bind(port).sync();
			m_logger.info(String.format("start netty server, bossThreads=%s, workerThreads=%s, maxMessageSize=%s!",
						bossThreads, workerThreads, m_maxMessageSize));
		} catch (Exception e) {
			m_logger.error("Started Netty Server Failed:" + port, e);
		}
	}

	public class MessageDecoder extends ByteToMessageDecoder {
		private final int m_maxFrameSize;

		private long m_processCount;

		public MessageDecoder(int maxMessageSize) {
			m_maxFrameSize = maxMessageSize;
		}

		@Override
		protected void decode(ChannelHandlerContext ctx, ByteBuf buffer, List<Object> out) throws Exception {
			if (buffer.readableBytes() < 4) {
				return;
			}
			int length = buffer.getInt(buffer.readerIndex());

			if (length <= 0 || length > m_maxFrameSize) {
				if (m_serverStateManager != null) {
					m_serverStateManager.addMessageTotalLoss(1);
				}
				if (m_logger != null) {
					m_logger.warn(String.format("Closing connection with invalid CAT message length %s (allowed: 1-%s).",
							length, m_maxFrameSize));
				}
				ctx.close();
				return;
			}

			if (buffer.readableBytes() < length + 4) {
				return;
			}

			ByteBuf frame = null;
			boolean bufferTransferred = false;

			try {
				frame = buffer.readRetainedSlice(length + 4);
				frame.markReaderIndex();

				DefaultMessageTree tree = (DefaultMessageTree) CodecHandler.decode(frame);

				frame.resetReaderIndex();
				tree.setBuffer(frame);
				m_handler.handle(tree);
				bufferTransferred = true;
				m_processCount++;

				long flag = m_processCount % CatConstants.SUCCESS_COUNT;

				if (flag == 0) {
					m_serverStateManager.addMessageTotal(CatConstants.SUCCESS_COUNT);
				}
			} catch (Exception e) {
				if (m_serverStateManager != null) {
					m_serverStateManager.addMessageTotalLoss(1);
				}
				if (m_logger != null) {
					m_logger.error(e.getMessage(), e);
				}
			} finally {
				if (!bufferTransferred) {
					ReferenceCountUtil.safeRelease(frame);
				}
			}
		}
	}

}
