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

import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Date;

import org.codehaus.plexus.logging.LogEnabled;
import org.codehaus.plexus.logging.Logger;
import org.unidal.helper.Threads.Task;

import com.dianping.cat.Cat;
import com.dianping.cat.CatConstants;
import com.dianping.cat.message.spi.MessageQueue;
import com.dianping.cat.message.spi.MessageTree;

public class PeriodTask implements Task, LogEnabled {

	private MessageAnalyzer m_analyzer;

	private MessageQueue m_queue;

	private long m_startTime;

	private int m_queueOverflow;

	private long m_enqueueCount;

	private int m_queueCapacity;

	private long m_lastQueuePressureLog;

	private Logger m_logger;

	private int m_index;

	public PeriodTask(MessageAnalyzer analyzer, MessageQueue queue, long startTime) {
		this(analyzer, queue, startTime, Integer.MAX_VALUE);
	}

	public PeriodTask(MessageAnalyzer analyzer, MessageQueue queue, long startTime, int queueCapacity) {
		m_analyzer = analyzer;
		m_queue = queue;
		m_startTime = startTime;
		m_queueCapacity = queueCapacity;
	}

	public void setIndex(int index) {
		m_index = index;
	}

	@Override
	public void enableLogging(Logger logger) {
		m_logger = logger;
	}

	public boolean enqueue(MessageTree tree) {
		if (m_analyzer.isEligable(tree)) {
			boolean result = m_queue.offer(tree);
			m_enqueueCount++;

			if (!result) { // trace queue overflow
				m_queueOverflow++;

				if (m_logger != null && (m_queueOverflow == 1 || m_queueOverflow % CatConstants.ERROR_COUNT == 0)) {
					String date = new SimpleDateFormat("yyyy-MM-dd HH:mm").format(new Date(m_analyzer.getStartTime()));

					m_logger.warn(String.format("%s queue rejected=%s depth=%s capacity=%s analyzerTime=%s",
							m_analyzer.getClass().getSimpleName(), m_queueOverflow, m_queue.size(), m_queueCapacity, date));
				}
			} else if (m_enqueueCount % CatConstants.SUCCESS_COUNT == 0) {
				logQueuePressure();
			}
			return result;
		} else {
			return true;
		}
	}

	private void logQueuePressure() {
		int depth = m_queue.size();
		long now = System.currentTimeMillis();

		if (m_logger != null && ((long) depth * 4 >= (long) m_queueCapacity * 3)
						&& now - m_lastQueuePressureLog >= 60 * 1000L) {
			m_lastQueuePressureLog = now;
			m_logger.warn(String.format("%s queue pressure depth=%s capacity=%s rejected=%s",
						m_analyzer.getClass().getSimpleName(), depth, m_queueCapacity, m_queueOverflow));
		}
	}

	public void finish() {
		try {
			m_analyzer.doCheckpoint(true);
			m_analyzer.destroy();
		} catch (Exception e) {
			Cat.logError(e);
		}
	}

	public MessageAnalyzer getAnalyzer() {
		return m_analyzer;
	}

	@Override
	public String getName() {
		Calendar cal = Calendar.getInstance();

		cal.setTimeInMillis(m_startTime);
		return m_analyzer.getClass().getSimpleName() + "-" + cal.get(Calendar.HOUR_OF_DAY) + "-" + m_index;
	}

	@Override
	public void run() {
		try {
			m_analyzer.analyze(m_queue);
		} catch (Exception e) {
			Cat.logError(e);
		}
	}

	@Override
	public void shutdown() {
		if (m_analyzer instanceof AbstractMessageAnalyzer) {
			((AbstractMessageAnalyzer<?>) m_analyzer).shutdown();
		}
	}
}
