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

import java.util.HashMap;
import java.util.Map;

import org.junit.Assert;
import org.junit.Test;

public class ServerConfigManagerTest {
	@Test
	public void testRealtimeAnalyzerQueueSize() {
		MockServerConfigManager manager = new MockServerConfigManager();

		Assert.assertEquals(10000, manager.getQueueSizeOfRealtimeAnalyzer("transaction"));

		manager.setProperty("realtime-analyzer-queue-size", "10000");
		Assert.assertEquals(10000, manager.getQueueSizeOfRealtimeAnalyzer("transaction"));

		manager.setProperty("transaction-analyzer-queue-size", "5000");
		Assert.assertEquals(5000, manager.getQueueSizeOfRealtimeAnalyzer("transaction"));

		manager.setProperty("transaction-analyzer-queue-size", "0");
		Assert.assertEquals(10000, manager.getQueueSizeOfRealtimeAnalyzer("transaction"));

		manager.setProperty("transaction-analyzer-queue-size", "invalid");
		Assert.assertEquals(10000, manager.getQueueSizeOfRealtimeAnalyzer("transaction"));
	}

	@Test
	public void testRealtimeAnalyzerSettingsAreReadDynamically() {
		MockServerConfigManager manager = new MockServerConfigManager();

		Assert.assertTrue(manager.getEnableOfRealtimeAnalyzer("business"));
		manager.setProperty("business-analyzer-enable", "false");
		Assert.assertFalse(manager.getEnableOfRealtimeAnalyzer("business"));

		manager.setProperty("business-analyzer-enable", "true");
		manager.setProperty("business-analyzer-queue-size", "8000");
		Assert.assertTrue(manager.getEnableOfRealtimeAnalyzer("business"));
		Assert.assertEquals(8000, manager.getQueueSizeOfRealtimeAnalyzer("business"));
	}

	private static class MockServerConfigManager extends ServerConfigManager {
		private Map<String, String> m_properties = new HashMap<String, String>();

		@Override
		public String getProperty(String name, String defaultValue) {
			String value = m_properties.get(name);

			return value == null ? defaultValue : value;
		}

		public void setProperty(String name, String value) {
			m_properties.put(name, value);
		}
	}
}
