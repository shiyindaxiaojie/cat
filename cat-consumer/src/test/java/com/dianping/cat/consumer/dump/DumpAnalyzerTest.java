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
package com.dianping.cat.consumer.dump;

import org.junit.Assert;
import org.junit.Test;

import com.dianping.cat.message.spi.internal.DefaultMessageTree;

import io.netty.buffer.ByteBuf;
import io.netty.buffer.PooledByteBufAllocator;

public class DumpAnalyzerTest {
	@Test
	public void testInvalidMessageReleasesBuffer() {
		DumpAnalyzer analyzer = new DumpAnalyzer();
		DefaultMessageTree tree = new DefaultMessageTree();
		ByteBuf buffer = PooledByteBufAllocator.DEFAULT.buffer(16);

		tree.setMessageId("invalid");
		tree.setBuffer(buffer);
		analyzer.process(tree);

		Assert.assertEquals(0, buffer.refCnt());
	}
}
