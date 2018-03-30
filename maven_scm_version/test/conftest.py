#!/usr/bin/python
# -*- coding: utf-8 -*-
# Maven use SCM version.
# Copyright (C) 2018 Patrik Dufresne Service Logiciel
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
"""
Created on Mar 30, 2018

@author: ikus060
"""

from __future__ import unicode_literals

from io import open
import itertools
import os
import pkg_resources
import subprocess


class Wd(object):
    commit_command = None
    add_command = None

    def __init__(self, cwd):
        self.cwd = cwd
        self.__counter = itertools.count()

    def __call__(self, cmd, **kw):
        if kw:
            cmd = cmd.format(**kw)
        return subprocess.check_output(cmd, cwd=self.cwd, shell=True)

    def write(self, name, value, **kw):
        filename = os.path.join(self. cwd, name)
        if kw:
            value = value.format(**kw)
        with open(filename, 'w', encoding='utf-8') as f:
            f.write(value)
        return filename

    def _reason(self, given_reason):
        if given_reason is None:
            return 'number-{c}'.format(c=next(self.__counter))
        else:
            return given_reason

    def commit(self, reason=None):
        reason = self._reason(reason)
        self(self.commit_command, reason=reason)

    def commit_testfile(self, reason=None):
        reason = self._reason(reason)
        self.write('test.txt', 'test {reason}', reason=reason)
        self(self.add_command)
        self.commit(reason=reason)

    def get_version(self, **kw):
        __tracebackhide__ = True
        version_sh = pkg_resources.resource_filename('maven_scm_version', '../version.sh')  # @UndefinedVariable
        version = subprocess.check_output(version_sh, shell=True, cwd=str(self.cwd), **kw).strip('\n')
        print(version)
        return version

    @property
    def version(self):
        __tracebackhide__ = True
        return self.get_version()
