#!/usr/bin/perl

package PiaMi::LocationDecoder;

use POSIX qw(floor);
use URI::Escape;

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  return $self;
}

sub decode {
  shift;
  my $param1 = shift;
  my ($loc_2, $loc_3, $loc_4, $loc_5, @loc_6, $loc_7, $loc_8, $loc_9, $loc_10);
  $loc_2 = substr $param1, 0, 1;
  $loc_3 = substr $param1, 1; 
  $loc_4 = floor(length($loc_3) / $loc_2);
  $loc_5 = length($loc_3) % $loc_2;
  $loc_7 = 0;
  while ( $loc_7 < $loc_5) {                
    if (! defined $loc_6[$loc_7]) {
      $loc_6[$loc_7] = "";
    }
    $loc_6[$loc_7] = substr($loc_3, ($loc_4 + 1) * $loc_7, ($loc_4 + 1));
    $loc_7 = $loc_7 + 1;
  }
  $loc_7 = $loc_5;
  while ($loc_7 < $loc_2) {    
    $loc_6[$loc_7] = substr($loc_3, $loc_4 * ($loc_7 - $loc_5) + ($loc_4 + 1) * $loc_5, $loc_4);
    $loc_7 = $loc_7 + 1;
  }
  $loc_8 = "";
  $loc_7 = 0;
  while ($loc_7 < length $loc_6[0]) {                
    $loc_10 = 0;
    while ($loc_10 <  @loc_6) {                    
      $loc_8 = $loc_8 . substr($loc_6[$loc_10], $loc_7, 1);
      $loc_10 = $loc_10 + 1;
    }
    $loc_7 = $loc_7 + 1;
  }
  $loc_8 = uri_unescape($loc_8);
  $loc_9 = "";
  $loc_7 = 0;
  while ($loc_7 < length $loc_8) {                
    if (substr($loc_8, $loc_7, 1) eq "^") {
      $loc_9 = $loc_9 . "0";
    } else {
      $loc_9 = $loc_9 . substr($loc_8, $loc_7, 1);
    }
    $loc_7 = $loc_7 + 1;
  }
  $loc_9 =~ s#\+# #;
  return $loc_9;
}

1;
