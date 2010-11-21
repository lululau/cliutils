#!/usr/bin/perl

#本脚本的功能是设置“标准”格式的mp3 id3标签或者将mp3文件的现有标签转换为
#“标准”格式。“标准”格式也就是采用带BOM的UTF-16LE编码字符串的id3v2.3.0标签格式。
#iTunes(Mac OS X)、Vox(Mac OS X)、Mac QuickLook(Mac OS X)、
#Totem Player(GNU/Linux/GNOME)、Rhythmbox(GNU/Linux/GNOME)、
#TTPlayer(Windows)、SonicStage(Windows)等多数播放器都支持这种“标准”格式。
#注意：本脚本只能在UTF-8环境的SHELL上运行。

BEGIN {

  #Windows以及Windows上的某些播放器仅支持id3v2 2.3.0的0(ISO-8859-1)和1(UTF-16 with BOM)两种编码格式，
  #当然它们更不支持2.4.0；
  #Mac的QuickLook对UTF-16BE的1编码的id3v2 2.3.0支持不好；
  #因此我们统一使用UTF-16LE 1号编码的id3v2 2.3.0
  #此外，MP3::Tag::ID3v2.pm中的as_bin子过程（804行）错误地将UTF-16LE BOM("\xff\xfe")转换为"\xff\x00\xfe"，
  #因此，在这里重新定义了as_bin子过程：
  #    $flags = chr(128) if ($self->get_config('id3v23_unsync'))->[0]
  #       and $tag_data =~ s/\xFF(?=[\x00\xE0-\xFD\xFF])/\xFF\x00/g;
  #注意！这种hack行为有可能导致其它BUG，本脚本仅仅支持有限的几种id3v2 frame，目前尚未发现其它问题。
  $ENV{MP3TAG_USE_UTF_16LE} = 1;
}

use strict;
use warnings;

use utf8;

use Encode qw(encode decode from_to);

use Getopt::Long;

use MP3::Tag;

use File::Basename;


binmode STDOUT, ":encoding(utf8)";

package MP3::Tag::ID3v2;
{
  no warnings qw(redefine);
  sub as_bin ($;$$$) {
    my ($self, $ignore_error, $update_file, $raw_ok) = @_;

    return $self->{raw_data}
      if $raw_ok and $self->{raw_data} and not $self->{modified} and not $update_file;

    die "Writing of ID3v2.4 is not fully supported (prohibited now via `write_v24').\n"
      if $self->{major} == 4 and not $self->get_config1('write_v24');
    if ($self->{major} > 4) {
      warn "Only writing of ID3v2.3 (and some tags of v2.4) is supported. Cannot convert ID3v".
        $self->{version}." to ID3v2.3 yet.\n";
      return undef;
    }

    # which order should tags have?

    $self->get_frame_ids;
    my $tag_data = $self->build_tag($ignore_error);
    return unless defined $tag_data;

    # printing this will ruin flags if they are \x80 or above.
    die "panic: prepared raw tag contains wide characters"
      if $tag_data =~ /[^\x00-\xFF]/;
    # perhaps search for first mp3 data frame to check if tag size is not
    # too big and will override the mp3 data
    #ext header are not supported yet
    my $flags = chr(0);
    #   $flags = chr(128) if ($self->get_config('id3v23_unsync'))->[0]############################## Commented by 刘向
    #     and $tag_data =~ s/\xFF(?=[\x00\xE0-\xFF])/\xFF\x00/g;     # sync flag#################### Commented by 刘向
    $flags = chr(128) if ($self->get_config('id3v23_unsync'))->[0] ############################## Added by 刘向
      and $tag_data =~ s/\xFF(?=[\x00\xE0-\xFD\xFF])/\xFF\x00/g; ############################## Added by 刘向
    $tag_data .= "\0"           # Terminated by 0xFF?
      if length $tag_data and chr(0xFF) eq substr $tag_data, -1, 1;
    my $n_tsize = length $tag_data;

    my $header = 'ID3' . chr(3) . chr(0);

    if ($update_file) {
      my $o_tsize = $self->{buggy_padding_size} + $self->{tagsize};
      my $add_padding = 0;
      if ( $o_tsize < $n_tsize
           or ($self->get_config('id3v2_shrink'))->[0] ) {
        # if creating new tag / increasing size add at least 128b padding
        # add additional bytes to make new filesize multiple of 512b
        my $mp3obj = $self->{mp3};
        my $filesize = (stat($mp3obj->{filename}))[7];
        my $extra = ($self->get_config('id3v2_minpadding'))->[0];
        my $n_filesize = ($filesize + $n_tsize - $o_tsize + $extra);
        my $round = ($self->get_config('id3v2_sizemult'))->[0];
        $n_filesize = (($n_filesize + $round - 1) & ~($round - 1));
        my $n_padding = $n_filesize - $filesize - ($n_tsize - $o_tsize);
        $n_tsize += $n_padding;
        if ($o_tsize != $n_tsize) {
          my @insert = [0, $o_tsize+10, $n_tsize + 10];
          return undef unless insert_space($self, \@insert) == 0;
        } else {           # Slot is not filled by 0; fill it manually
          $add_padding = $n_padding - $self->{buggy_padding_size};
        }
        $self->{tagsize} = $n_tsize;
      } else {                # Include current "padding" into n_tsize
        $add_padding = $self->{tagsize} - $n_tsize;
        $n_tsize = $self->{tagsize} = $o_tsize;
      }
      $add_padding = 0 if $add_padding < 0;
      $tag_data .= "\0" x $add_padding if $update_file =~ /padding/;
    }

    #convert size to header format specific size
    my $size = unpack('B32', pack ('N', $n_tsize));
    substr ($size, -$_, 0) = '0' for (qw/28 21 14 7/);
    $size= pack('B32', substr ($size, -32));

    return "$header$flags$size$tag_data";
  }
}

package ITagEdit::ITagWriter;

sub new {
  my $class = shift;
  my $self = {@_};

  $self->{mp3} = MP3::Tag->new($self->{file_name});
  $self->{mp3}->get_tags();
  if (exists $self->{mp3}->{ID3v2}) {
    $self->{id3v2} = $self->{mp3}->{ID3v2};
  } else {
    $self->{id3v2} = $self->{mp3}->new_tag("id3v2");
  }  
  bless $self, $class;
  return $self;
}

sub write {
  my $self = shift;
  my $args = {@_};
  if (exists $args->{file_name}) {
    
    $self->{mp3} = MP3::Tag->new($self->{file_name});
    $self->{mp3}->get_tags();
    if (exists $self->{mp3}->{ID3v2}) {
      $self->{id3v2} = $self->{mp3}->{ID3v2};
    } else {
      $self->{id3v2} = $self->{mp3}->new_tag("id3v2");
    }  
  }
  $self->add_lx_title($args->{title});
  $self->add_lx_artist($args->{artist});
  $self->add_lx_album($args->{album});
  $self->add_lx_cover($args->{cover});
  $self->{id3v2}->write_tag();
}


sub add_lx_artist{
  my ($self, $artist) = @_;
  $self->{mp3}->select_id3v2_frame_by_descr("TPE1", undef);
  $self->{id3v2}->add_frame("TPE1", 1, $artist);
}

sub add_lx_title {
  my($self, $title) = @_;
  $self->{mp3}->select_id3v2_frame_by_descr("TIT2", undef);
  $self->{id3v2}->add_frame("TIT2", 1, $title);
}

sub add_lx_album{
  my($self, $album) = @_;
  $self->{mp3}->select_id3v2_frame_by_descr("TALB", undef);
  $self->{id3v2}->add_frame("TALB", 1, $album);
}

sub add_lx_cover {
  my($self, $img_data) = @_;
  my $mime = "image/jpeg";
  $self->{mp3}->select_id3v2_frame_by_descr("APIC", undef);
  $self->{id3v2}->add_frame("APIC", 0, $mime, "\x03", "", $img_data);
}

sub add_lx_year {
  my($self, $year) = @_;
  $self->{mp3}->select_id3v2_frame_by_descr("TYER", undef);
  $self->{id3v2}->add_frame("TYER", $year);
}

sub add_lx_genre {
  my($self, $genre) = @_;
  $self->{mp3}->select_id3v2_frame_by_descr("TCON", undef);
  $self->{id3v2}->add_frame("TCON", 0, $genre);
}

sub add_lx_track_num {
  my($self, $track_num) = @_;
  $self->{mp3}->select_id3v2_frame_by_descr("TRCK", undef);
  $self->{id3v2}->add_frame("TRCK", $track_num);
}

1;
