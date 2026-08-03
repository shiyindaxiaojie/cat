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
package com.dianping.cat.report.page.logview.service;

import java.nio.charset.StandardCharsets;

import io.netty.buffer.ByteBuf;
import io.netty.buffer.Unpooled;
import org.junit.Assert;
import org.junit.Test;

public class LocalMessageServiceTest {
	@Test
	public void testMessageFrameIsBoundedWithoutAdvancingSource() {
		ByteBuf source = Unpooled.buffer();

		source.writeInt(6);
		source.writeBytes("PT1abc".getBytes(StandardCharsets.UTF_8));
		source.writeInt(3);
		source.writeBytes("end".getBytes(StandardCharsets.UTF_8));

		ByteBuf frame = LocalMessageService.messageFrame(source);

		Assert.assertEquals(0, source.readerIndex());
		Assert.assertEquals(10, frame.readableBytes());
		Assert.assertEquals(6, frame.readInt());
		Assert.assertEquals("PT1abc", frame.toString(StandardCharsets.UTF_8));
	}

	@Test(expected = IllegalArgumentException.class)
	public void testMessageFrameRejectsTruncatedData() {
		ByteBuf source = Unpooled.buffer();

		source.writeInt(10);
		source.writeBytes("short".getBytes(StandardCharsets.UTF_8));

		LocalMessageService.messageFrame(source);
	}
}
