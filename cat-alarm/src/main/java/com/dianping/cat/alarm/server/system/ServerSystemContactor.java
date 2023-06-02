/*
 * Copyright 2012-2019 the original author or authors.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.dianping.cat.alarm.server.system;

import com.dianping.cat.alarm.receiver.entity.Receiver;
import com.dianping.cat.alarm.server.TagSplitHelper;
import com.dianping.cat.alarm.spi.AlertType;
import com.dianping.cat.alarm.spi.config.AlertConfigManager;
import com.dianping.cat.alarm.spi.receiver.Contactor;
import com.dianping.cat.alarm.spi.receiver.ProjectContactor;
import com.dianping.cat.core.dal.Project;
import com.dianping.cat.service.ProjectService;
import org.unidal.lookup.annotation.Inject;

import java.util.ArrayList;
import java.util.List;

public class ServerSystemContactor extends ProjectContactor implements Contactor {

	public static final String ID = AlertType.SERVER_SYSTEM.getName();

	@Inject
	private ProjectService m_projectService;

	@Inject
	protected AlertConfigManager m_configManager;

	@Override
	public String getId() {
		return ID;
	}

	@Override
	public List<String> queryDXContactors(String id) {
		List<String> mailReceivers = new ArrayList<String>();
		Receiver receiver = m_configManager.queryReceiverById(getId());

		if (receiver != null && !receiver.isEnable()) {
			return mailReceivers;
		} else {
			mailReceivers.addAll(buildDefaultDXReceivers(receiver));

			String domain = TagSplitHelper.queryDomain(id);
			Project project = m_projectService.findByDomain(domain);

			if (project != null) {
				mailReceivers.addAll(split(project.getEmail()));
			}
			return mailReceivers;
		}
	}

	@Override
	public List<String> queryEmailContactors(String id) {
		List<String> mailReceivers = new ArrayList<String>();
		Receiver receiver = m_configManager.queryReceiverById(getId());

		if (receiver != null && !receiver.isEnable()) {
			return mailReceivers;
		} else {
			mailReceivers.addAll(buildDefaultMailReceivers(receiver));

			String domain = TagSplitHelper.queryDomain(id);
			Project project = m_projectService.findByDomain(domain);

			if (project != null) {
				mailReceivers.addAll(split(project.getEmail()));
			}
			return mailReceivers;
		}
	}

	@Override
	public List<String> querySmsContactors(String id) {
		List<String> smsReceivers = new ArrayList<String>();
		Receiver receiver = m_configManager.queryReceiverById(getId());

		if (receiver != null && !receiver.isEnable()) {
			return smsReceivers;
		} else {
			smsReceivers.addAll(buildDefaultSMSReceivers(receiver));

			String domain = TagSplitHelper.queryDomain(id);
			Project project = m_projectService.findByDomain(domain);

			if (project != null) {
				smsReceivers.addAll(split(project.getPhone()));
			}
			return smsReceivers;
		}
	}

	@Override
	public List<String> queryWeiXinContactors(String id) {
		List<String> weixinReceivers = new ArrayList<String>();
		Receiver receiver = m_configManager.queryReceiverById(getId());

		if (receiver != null && !receiver.isEnable()) {
			return weixinReceivers;
		} else {
			weixinReceivers.addAll(buildDefaultWeixinReceivers(receiver));

			String domain = TagSplitHelper.queryDomain(id);
			Project project = m_projectService.findByDomain(domain);

			if (project != null) {
				weixinReceivers.addAll(split(project.getEmail()));
			}
			return weixinReceivers;
		}
	}

}
