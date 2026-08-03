/*
 * Copyright (c) 2011-2018, Meituan Dianping. All Rights Reserved.
 *
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 */
package com.dianping.cat.analysis;

import java.lang.reflect.Field;
import java.util.concurrent.atomic.AtomicReference;

import org.junit.Assert;
import org.junit.Test;

import com.dianping.cat.message.io.BufReleaseHelper;
import com.dianping.cat.message.spi.MessageTree;
import com.dianping.cat.message.spi.codec.PlainTextMessageCodec;
import com.dianping.cat.message.spi.internal.DefaultMessageTree;

import io.netty.buffer.ByteBuf;
import io.netty.buffer.Unpooled;
import io.netty.channel.embedded.EmbeddedChannel;

public class TcpSocketReceiverTest {
	@Test
	public void testAcceptedFrameOwnershipIsTransferredToHandler() throws Exception {
		final AtomicReference<ByteBuf> transferred = new AtomicReference<ByteBuf>();
		TcpSocketReceiver receiver = receiverWithHandler(new MessageHandler() {
			@Override
			public boolean handle(MessageTree message) {
				transferred.set(message.getBuffer());
				return true;
			}
		});
		EmbeddedChannel channel = new EmbeddedChannel(receiver.new MessageDecoder(1024));
		ByteBuf frame = newFrame();

		channel.writeInbound(frame);

		Assert.assertNotNull(transferred.get());
		Assert.assertEquals(1, frame.refCnt());
		Assert.assertEquals(1, transferred.get().refCnt());
		BufReleaseHelper.release(transferred.get());
		Assert.assertEquals(0, frame.refCnt());
		channel.finishAndReleaseAll();
	}

	@Test
	public void testRejectedFrameIsReleasedByReceiver() throws Exception {
		TcpSocketReceiver receiver = receiverWithHandler(new MessageHandler() {
			@Override
			public boolean handle(MessageTree message) {
				return false;
			}
		});
		EmbeddedChannel channel = new EmbeddedChannel(receiver.new MessageDecoder(1024));
		ByteBuf frame = newFrame();

		channel.writeInbound(frame);

		Assert.assertEquals(0, frame.refCnt());
		channel.finishAndReleaseAll();
	}

	@Test
	public void testOversizedFrameClosesConnectionWithoutWaitingForPayload() {
		TcpSocketReceiver receiver = new TcpSocketReceiver();
		EmbeddedChannel channel = new EmbeddedChannel(receiver.new MessageDecoder(1024));
		ByteBuf header = Unpooled.buffer(4).writeInt(1025);

		channel.writeInbound(header);

		Assert.assertFalse(channel.isOpen());
		channel.finishAndReleaseAll();
		Assert.assertEquals(0, header.refCnt());
	}

	@Test
	public void testNonPositiveFrameClosesConnection() {
		TcpSocketReceiver receiver = new TcpSocketReceiver();
		EmbeddedChannel channel = new EmbeddedChannel(receiver.new MessageDecoder(1024));
		ByteBuf header = Unpooled.buffer(4).writeInt(0);

		channel.writeInbound(header);

		Assert.assertFalse(channel.isOpen());
		channel.finishAndReleaseAll();
		Assert.assertEquals(0, header.refCnt());
	}

	private ByteBuf newFrame() {
		DefaultMessageTree tree = new DefaultMessageTree();

		tree.setDomain("cat");
		tree.setHostName("host");
		tree.setIpAddress("127.0.0.1");
		tree.setThreadGroupName("group");
		tree.setThreadId("1");
		tree.setThreadName("main");
		tree.setMessageId("");
		tree.setParentMessageId("");
		tree.setRootMessageId("");
		tree.setSessionToken("");
		return new PlainTextMessageCodec().encode(tree);
	}

	private TcpSocketReceiver receiverWithHandler(MessageHandler handler) throws Exception {
		TcpSocketReceiver receiver = new TcpSocketReceiver();
		Field field = TcpSocketReceiver.class.getDeclaredField("m_handler");

		field.setAccessible(true);
		field.set(receiver, handler);
		return receiver;
	}
}
