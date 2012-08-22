#!/usr/bin/env perl
use Dancer;
use mongoperlbrowser;

set 'session'     => 'Simple';
#set 'logger'      => 'console';
#set 'log'         => 'debug';
#set 'show_errors' => 1;
#set 'access_log ' => 1;
#set 'warnings'    => 1;
set 'username' => 'admin';
set 'password' => 'passwd';

dance;
