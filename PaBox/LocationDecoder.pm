#!/usr/bin/perl

package PaBox::LocationDecoder;

use URI::Escape::XS;

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  return $self;
}

sub decode {
  my($self, $str) = @_;
  $str = decodeURIComponent $str;
  my $result = "";
  my $t = 36;
  for (my $i = 0; $i < length $str; $i++) {    
    $result .= chr(ord(substr($str, $i, 1)) ^ $t);
  }
  return $result;
}

1;
