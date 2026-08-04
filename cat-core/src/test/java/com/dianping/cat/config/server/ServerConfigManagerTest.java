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

		Assert.assertEquals(10000, manager.getQueueCapacityPerThreadOfRealtimeAnalyzer("transaction"));

		manager.setProperty("realtime-analyzer-queue-capacity-per-thread", "10000");
		Assert.assertEquals(10000, manager.getQueueCapacityPerThreadOfRealtimeAnalyzer("transaction"));

		manager.setProperty("transaction-analyzer-queue-capacity-per-thread", "5000");
		Assert.assertEquals(5000, manager.getQueueCapacityPerThreadOfRealtimeAnalyzer("transaction"));

		manager.setProperty("transaction-analyzer-queue-capacity-per-thread", "0");
		Assert.assertEquals(10000, manager.getQueueCapacityPerThreadOfRealtimeAnalyzer("transaction"));

		manager.setProperty("transaction-analyzer-queue-capacity-per-thread", "invalid");
		Assert.assertEquals(10000, manager.getQueueCapacityPerThreadOfRealtimeAnalyzer("transaction"));
	}

	@Test
	public void testRealtimeAnalyzerSettingsAreReadDynamically() {
		MockServerConfigManager manager = new MockServerConfigManager();

		Assert.assertTrue(manager.getEnableOfRealtimeAnalyzer("business"));
		manager.setProperty("business-analyzer-enable", "false");
		Assert.assertFalse(manager.getEnableOfRealtimeAnalyzer("business"));

		manager.setProperty("business-analyzer-enable", "true");
		manager.setProperty("business-analyzer-queue-capacity-per-thread", "8000");
		Assert.assertTrue(manager.getEnableOfRealtimeAnalyzer("business"));
		Assert.assertEquals(8000, manager.getQueueCapacityPerThreadOfRealtimeAnalyzer("business"));
	}

	@Test
	public void testResourceSafetySettings() {
		MockServerConfigManager manager = new MockServerConfigManager();

		Assert.assertEquals(1, manager.getNettyBossThreads());
		Assert.assertEquals(2, manager.getNettyWorkerThreads());
		Assert.assertTrue(manager.isConsumerMachine());
		Assert.assertEquals(4 * 1024 * 1024, manager.getMaxMessageSize());
		Assert.assertEquals(8, manager.getMessageProcessorThreads());
		Assert.assertEquals(5000, manager.getMessageProcessorQueueSize());
		Assert.assertEquals(32, manager.getReportQueryThreads());

		manager.setProperty("netty-worker-threads", "2");
		manager.setProperty("max-message-size", "1048576");
		manager.setProperty("message-processor-queue-size", "2500");
		Assert.assertEquals(2, manager.getNettyWorkerThreads());
		Assert.assertEquals(1024 * 1024, manager.getMaxMessageSize());
		Assert.assertEquals(2500, manager.getMessageProcessorQueueSize());

		manager.setProperty("netty-worker-threads", "invalid");
		manager.setProperty("max-message-size", String.valueOf(65 * 1024 * 1024));
		Assert.assertEquals(2, manager.getNettyWorkerThreads());
		Assert.assertEquals(4 * 1024 * 1024, manager.getMaxMessageSize());

		manager.setProperty("netty-worker-threads", "auto");
		manager.setProperty("consumer-machine", "false");
		Assert.assertEquals(2, manager.getNettyWorkerThreads());
		Assert.assertFalse(manager.isConsumerMachine());

		manager.setDetectedCpu(64, -1, true);
		Assert.assertEquals(1, manager.getNettyWorkerThreads());

		manager.setDetectedCpu(64, -1, false);
		Assert.assertEquals(4, manager.getNettyWorkerThreads());

		manager.setDetectedCpu(64, 8, true);
		Assert.assertEquals(4, manager.getNettyWorkerThreads());
	}

	@Test
	public void testCheckpointSettings() {
		MockServerConfigManager manager = new MockServerConfigManager();

		Assert.assertTrue(manager.isDailyCheckpointEnabled());
		Assert.assertEquals(4, manager.getDailyCheckpointHour());
		Assert.assertEquals(0, manager.getDailyCheckpointMinute());
		Assert.assertEquals(25, manager.getGracefulShutdownTimeoutSeconds());

		manager.setProperty("daily-checkpoint-enabled", "false");
		manager.setProperty("daily-checkpoint-hour", "23");
		manager.setProperty("daily-checkpoint-minute", "59");
		manager.setProperty("graceful-shutdown-timeout-seconds", "60");
		Assert.assertFalse(manager.isDailyCheckpointEnabled());
		Assert.assertEquals(23, manager.getDailyCheckpointHour());
		Assert.assertEquals(59, manager.getDailyCheckpointMinute());
		Assert.assertEquals(60, manager.getGracefulShutdownTimeoutSeconds());

		manager.setProperty("daily-checkpoint-hour", "24");
		manager.setProperty("daily-checkpoint-minute", "-1");
		manager.setProperty("graceful-shutdown-timeout-seconds", "0");
		Assert.assertEquals(4, manager.getDailyCheckpointHour());
		Assert.assertEquals(0, manager.getDailyCheckpointMinute());
		Assert.assertEquals(25, manager.getGracefulShutdownTimeoutSeconds());
	}

	private static class MockServerConfigManager extends ServerConfigManager {
		private int m_cgroupProcessors = 2;

		private boolean m_kubernetes = true;

		private Map<String, String> m_properties = new HashMap<String, String>();

		private int m_runtimeProcessors = 8;

		@Override
		protected int getCgroupCpuLimit() {
			return m_cgroupProcessors;
		}

		@Override
		protected int getRuntimeAvailableProcessors() {
			return m_runtimeProcessors;
		}

		@Override
		protected boolean isKubernetesEnvironment() {
			return m_kubernetes;
		}

		@Override
		public String getProperty(String name, String defaultValue) {
			String value = m_properties.get(name);

			return value == null ? defaultValue : value;
		}

		public void setProperty(String name, String value) {
			m_properties.put(name, value);
		}

		public void setDetectedCpu(int runtimeProcessors, int cgroupProcessors, boolean kubernetes) {
			m_runtimeProcessors = runtimeProcessors;
			m_cgroupProcessors = cgroupProcessors;
			m_kubernetes = kubernetes;
		}
	}
}
