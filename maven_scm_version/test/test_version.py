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

import shutil
import tempfile
import unittest

from maven_scm_version.test.conftest import Wd


class Test(unittest.TestCase):

    def setUp(self):
        wd = Wd(tempfile.mkdtemp('wd_scm_version'))
        wd('git init')
        wd('git config user.email test@example.com')
        wd('git config user.name "a test"')
        wd.add_command = 'git add .'
        wd.commit_command = 'git commit -m test-{reason}'
        self.wd = wd

    def tearDown(self):
        shutil.rmtree(self.wd.cwd)

    def test_version_from_git(self):
        assert self.wd.version.startswith('0.0.1-0')

        self.wd.commit_testfile()
        assert self.wd.version.startswith('0.0.1-1-g')
        assert not self.wd.version.endswith('1-')

        self.wd('git tag v1.0.1')
        self.assertEqual(self.wd.version, '1.0.1')

        self.wd.write('test.txt', 'test2')
        assert self.wd.version.startswith('1.0.1-d')

        self.wd.commit_testfile()
        assert self.wd.version.startswith('1.0.2-1-g')

        self.wd('git tag version-1.0.2')
        assert self.wd.version.startswith('1.0.2')

        self.wd.commit_testfile()
        self.wd('git tag version-1.0.2.alpha210-gbe48adfpost3-g0cc25f2')
        assert self.wd.version.startswith('1.0.2')

    def test_git_worktree(self):
        self.wd.write('test.txt', 'test2')
        # untracked files dont change the state
        assert self.wd.version == '0.0.1-0'
        self.wd('git add test.txt')
        assert self.wd.version.startswith('0.0.1-0')

    def test_git_dirty_notag(self):
        self.wd.commit_testfile()
        self.wd.write('test.txt', 'test2')
        self.wd("git add test.txt")
        assert self.wd.version.startswith('0.0.1-1-g')


if __name__ == "__main__":
    # import sys;sys.argv = ['', 'Test.testName']
    unittest.main()
