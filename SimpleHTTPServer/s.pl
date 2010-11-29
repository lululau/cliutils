#!/usr/bin/perl

use HTTP::Server::Brick;

my $port = 8080;
$port = $ARGV[0] if @ARGV == 1 && $ARGV[0] =~ /^\d+$/ && $ARGV[0] >=0 && $ARGV[0] <= 65535;

my $server = HTTP::Server::Brick->new(port => $port);
$server->mount("/" => {path => "."});
$server->start();
