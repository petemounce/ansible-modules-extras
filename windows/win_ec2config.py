#!/usr/bin/python
# -*- coding: utf-8 -*-

# (c) 2015, Peter Mounce <public@neverrunwithscissors.com>
#
# This file is part of Ansible
#
# Ansible is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Ansible is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Ansible.  If not, see <http://www.gnu.org/licenses/>.

# this is a windows documentation stub.  actual code lives in the .ps1
# file of the same name

DOCUMENTATION = '''
---
module: win_ec2config
version_added: "2.0"
short_description: Configure and invoke AWS ec2config
description:
  - ec2config is a windows service by AWS to allow access to advanced features for windows EC2 instances.
  - documentation (look up values here): http://docs.aws.amazon.com/AWSEC2/latest/WindowsGuide/UsingConfig_WinAMI.html#UsingConfigXML_WinAMI
  - release notes: https://aws.amazon.com/developertools/5562082477397515
options:
  Ec2HandleUserData:
    description:
      - Whether or not to process user-data scripts on next boot
    choices:
      - Enabled
      - Disabled
    required: false
    default: Enabled
  Ec2SetPassword:
    description:
      - Enabled: generate a random password for Administrator on each instance launch
      - Disabled: password is not changed
    choices:
      - Enabled
      - Disabled
    required: false
    default: Enabled
  sysprep:
    description:
      - Run sysprep and shutdown the instance so an AMI can be created from it
      - This will run after ec2config has been configured
      - This will leave the instance in a stopped state
    choices:
      - yes
      - no
    required: false
    default: no
author: Peter Mounce
'''

EXAMPLES = '''
  # Configure ec2config to process user data & randomise Administrator password, then sysprep & shutdown
  win_ec2config: user_data=yes password=randomise sysprep=yes

  # Run ec2config and tell it to sysprep then shutdown the instance with whatever the current configuration is
  win_ec2config: sysprep=yes
'''
