#!/usr/bin/perl

package PiaMi::Track;

use Class::Struct;
use PiaMi::LocationDecoder;

struct PiaMi::Track => {
			title => '$',
			song_id => '$',
			album_id => '$',
			album_name => '$',
			object_id => '$',
			object_name => '$',
			insert_type => '$',
			background => '$',
			grade => '$',
			artist => '$',
			location => '$',
			ms => '$',
			lyric => '$',
			pic => '$',
		       };

sub parse {
  my $track_ref = shift;  
  my $track = PiaMi::Track->new();
  my $decoder = PiaMi::LocationDecoder->new();
  $track->title($track_ref->{title}[0]);
  $track->song_id($track_ref->{song_id}[0]);
  $track->album_id($track_ref->{album_id}[0]);
  $track->album_name($track_ref->{album_name}[0]);
  $track->object_id($track_ref->{object_id}[0]);
  $track->object_name($track_ref->{object_name}[0]);
  $track->insert_type($track_ref->{insert_type}[0]);
  $track->background($track_ref->{background}[0]);
  $track->grade($track_ref->{grade}[0]);
  $track->artist($track_ref->{artist}[0]);
  $track->location($decoder->decode($track_ref->{location}[0]));
  $track->ms($track_ref->{ms}[0]);
  $track->lyric($track_ref->{lyric}[0]);
  $track->pic($track_ref->{pic}[0]);
  return $track;
}

1;
