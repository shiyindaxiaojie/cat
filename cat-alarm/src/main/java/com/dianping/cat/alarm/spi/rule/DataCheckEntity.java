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
package com.dianping.cat.alarm.spi.rule;

import java.util.Date;
import java.util.Set;

public class DataCheckEntity {
	private boolean m_isTriggered;

	private String m_content;

	private String m_alertLevel;

	private Date m_alertTime;

	private Set<String> m_ips;

	public DataCheckEntity(boolean result, String content, String alertLevel) {
		m_isTriggered = result;
		m_content = content;
		m_alertLevel = alertLevel;
		m_alertTime = new Date();
	}

	public DataCheckEntity(boolean m_isTriggered, String m_content, String m_alertLevel, Set<String> m_ips) {
		this.m_isTriggered = m_isTriggered;
		this.m_content = m_content;
		this.m_alertLevel = m_alertLevel;
		this.m_alertTime = new Date();
		this.m_ips = m_ips;
	}

	public String getAlertLevel() {
		return m_alertLevel;
	}

	public Date getAlertTime() {
		return m_alertTime;
	}

	public String getContent() {
		return m_content;
	}

	public void setContent(String content) {
		m_content = content;
	}

	public boolean isTriggered() {
		return m_isTriggered;
	}

	public Set<String> getIps() {
		return m_ips;
	}

	public void setIps(Set<String> m_ips) {
		this.m_ips = m_ips;
	}
}
