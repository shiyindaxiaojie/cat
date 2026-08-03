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

import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.junit.Assert;
import org.junit.Test;

import com.dianping.cat.config.server.ServerConfigManager;
import com.dianping.cat.message.spi.MessageQueue;
import com.dianping.cat.message.spi.MessageTree;
import com.dianping.cat.message.spi.internal.DefaultMessageTree;
import com.dianping.cat.report.ReportManager;
import com.dianping.cat.statistic.ServerStatisticManager;

public class PeriodConfigTest {
	@Test
	public void testAnalyzerEnableSettingAppliesToNewPeriod() {
		MockServerConfigManager configManager = new MockServerConfigManager();
		MockAnalyzer analyzer = new MockAnalyzer();
		MockAnalyzerManager analyzerManager = new MockAnalyzerManager("business", analyzer);

		configManager.setProperty("business-analyzer-enable", "false");
		Period disabled = newPeriod(analyzerManager, configManager);
		Assert.assertTrue(disabled.getAnalyzer("business").isEmpty());

		configManager.setProperty("business-analyzer-enable", "true");
		Period enabled = newPeriod(analyzerManager, configManager);
		Assert.assertEquals(1, enabled.getAnalyzer("business").size());
	}

	@Test
	public void testAnalyzerQueueSizeSettingAppliesToNewPeriod() {
		MockServerConfigManager configManager = new MockServerConfigManager();
		MockAnalyzerManager analyzerManager = new MockAnalyzerManager("transaction", new MockAnalyzer());
		configManager.setProperty("transaction-analyzer-queue-size", "2");
		Period period = newPeriod(analyzerManager, configManager);

		period.distribute(newTree("cat"));
		period.distribute(newTree("cat"));
		MessageTree overflow = newTree("cat");
		period.distribute(overflow);

		Assert.assertTrue(overflow.isProcessLoss());
	}

	@Test
	public void testBufferOwnershipTransfersOnlyWhenDumpQueueAcceptsMessage() {
		MockServerConfigManager configManager = new MockServerConfigManager();
		MockAnalyzerManager analyzerManager = new MockAnalyzerManager("dump", new MockAnalyzer());
		configManager.setProperty("dump-analyzer-queue-size", "1");
		Period period = newPeriod(analyzerManager, configManager);

		Assert.assertTrue(period.distribute(newTree("cat")));
		Assert.assertFalse(period.distribute(newTree("cat")));
	}

	private MessageTree newTree(String domain) {
		DefaultMessageTree tree = new DefaultMessageTree();

		tree.setDomain(domain);
		return tree;
	}

	private Period newPeriod(MessageAnalyzerManager analyzerManager, ServerConfigManager configManager) {
		long startTime = System.currentTimeMillis();

		return new Period(startTime, startTime + 1000, analyzerManager, new ServerStatisticManager(), configManager, null);
	}

	private static class MockAnalyzer implements MessageAnalyzer {
		@Override
		public void analyze(MessageQueue queue) {
		}

		@Override
		public void destroy() {
		}

		@Override
		public void doCheckpoint(boolean atEnd) {
		}

		@Override
		public int getAnanlyzerCount(String name) {
			return 1;
		}

		@Override
		public ReportManager<?> getReportManager() {
			return null;
		}

		@Override
		public long getStartTime() {
			return 0;
		}

		@Override
		public void initialize(long startTime, long duration, long extraTime) {
		}

		@Override
		public boolean isEligable(MessageTree tree) {
			return true;
		}

		@Override
		public void setIndex(int index) {
		}
	}

	private static class MockAnalyzerManager implements MessageAnalyzerManager {
		private MessageAnalyzer m_analyzer;

		private String m_name;

		public MockAnalyzerManager(String name, MessageAnalyzer analyzer) {
			m_name = name;
			m_analyzer = analyzer;
		}

		@Override
		public List<MessageAnalyzer> getAnalyzer(String name, long startTime) {
			return Collections.singletonList(m_analyzer);
		}

		@Override
		public List<String> getAnalyzerNames() {
			return Arrays.asList(m_name);
		}
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
