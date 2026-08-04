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
package com.dianping.cat.config.server;

import com.dianping.cat.configuration.server.entity.Server;
import com.dianping.cat.configuration.server.entity.ServerConfig;
import com.dianping.cat.configuration.server.transform.DefaultSaxParser;
import org.junit.Assert;
import org.junit.Test;

public class ServerConfigValidatorTest {
	@Test
	public void testInitializeAnalyzerPropertiesWithoutOverwritingExistingValues() throws Exception {
		String xml = "<server-config><server id=\"default\"><properties>"
						+ "<property name=\"business-analyzer-enable\" value=\"false\"/>"
						+ "</properties></server></server-config>";
		ServerConfig config = DefaultSaxParser.parse(xml);

		config.accept(new ServerConfigValidator());

		Server server = config.findServer(ServerConfigManager.DEFAULT);

		Assert.assertEquals("10000",
						server.findProperty("realtime-analyzer-queue-capacity-per-thread").getValue());
		Assert.assertEquals("false", server.findProperty("business-analyzer-enable").getValue());
		Assert.assertEquals("true", server.findProperty("matrix-analyzer-enable").getValue());
		Assert.assertEquals("true", server.findProperty("dependency-analyzer-enable").getValue());
		Assert.assertEquals("true", server.findProperty("top-analyzer-enable").getValue());
		Assert.assertEquals("true", server.findProperty("storage-analyzer-enable").getValue());
	}
}
