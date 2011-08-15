#!/usr/bin/perl 

use warnings;
use strict;
use utf8;

use Encode qw(encode decode);
use POSIX qw(strftime locale_h);
use File::Basename;
use IO::Socket;
use threads;
use LWP::MediaTypes qw(guess_media_type);

sub sigpipe_handler {
  print "yes";
}

$SIG{PIPE} = "IGNORE";

my $uuid = "D24EC059-2F1A-4848-B7A8-81A31383082F";
# 默认端口号
my $DEFAULT_PORT = 1111;
my $CRLF = "\015\012";
my $show_all_files = 0;

# 服务器端口号
my $server_port;

# 处理命令行参数
if (@ARGV == 1  && $ARGV[0] =~ /^\d+$/) {
  $server_port = $ARGV[0];
} elsif (@ARGV == 0) {
  $server_port = $DEFAULT_PORT;
} elsif (@ARGV == 2 && $ARGV[0] =~ /^\d+$/ && $ARGV[1] eq "-a") {
  $server_port = $ARGV[0];
  $show_all_files = 1;
} elsif (@ARGV == 1 && $ARGV[0] eq "-a") {
  $server_port = $DEFAULT_PORT;
  $show_all_files = 1;
} else {
  print STDERR "phs <端口号> <-a>\n";
  print STDERR "   默认端口号: 1111\n";
  print STDERR "   -a  显示隐藏文件";
  exit(1);  
}

# 在/tmp目录中生成资源文件
if (! -e "/tmp/$uuid") {
  binmode DATA;  
  open my $tar_fh, "|tar -C /tmp -zxf - ";
  binmode $tar_fh;
  print $tar_fh $_ while <DATA>;
}

my($html_1, $html_1_filename);
$html_1_filename = "/tmp/$uuid/1.html";
open my $html_1_fh, "<", $html_1_filename;
$html_1 .= $_ while <$html_1_fh>;
$html_1 = decode("utf8", $html_1);

my($html_11, $html_11_filename);
$html_11_filename = "/tmp/$uuid/11.html";
open my $html_11_fh, "<", $html_11_filename;
$html_11 .= $_ while <$html_11_fh>;
$html_11 = decode("utf8", $html_11);

my($html_2, $html_2_filename);
$html_2_filename = "/tmp/$uuid/2.html";
open my $html_2_fh, "<", $html_2_filename;
$html_2 .= $_ while <$html_2_fh>;
$html_2 = decode("utf8", $html_2);

my($html_22, $html_22_filename);
$html_22_filename = "/tmp/$uuid/22.html";
open my $html_22_fh, "<", $html_22_filename;
$html_22 .= $_ while <$html_22_fh>;
$html_22 = decode("utf8", $html_22);

# 创建TCP Socket服务器实例
my $server = IO::Socket::INET->new(
			     LocalPort => $server_port,
			     ReuseAddr => 1,
			     Listen => 10  # Listen是什么意思
			    );

while (my $client = $server->accept) {
  # 启动线程处理TCP请求
  async(sub {
	  
	  # Socket句柄
	  my $client = shift;
	   
	  # Protocol和HTTP Header
	  my($protocol, $headers);
	  $protocol = <$client>;
	  while (<$client>) {
	    last if /^\s*$/;

	    # 读取 Header
	    my($k, $v) = ($_ =~ /(.*?): (.*)/);
	    $headers->{$k} = $v;
	    }


	  # 获取Path
	  my ($req_path) = $protocol =~ /\S* (\S*) /;
	  (my $quest_string = $req_path) =~ s#.*\?##;
	  $req_path =~ s#\?.*$##;
	  my $filename = ".$req_path";

	  # 处理escaped characters
	  $filename =~ s#%([0-9a-zA-Z]{2})#pack "c", hex($1)#ge;


	  if ($headers->{"User-Agent"} =~ /ie/i && $req_path !~ /$uuid/o) {
	    print $client "HTTP/1.1 301 Moved Permanently$CRLF";
	    print $client "Location: /$uuid/noie.html$CRLF";
	    print $client "$CRLF";
	    return;
	  }

	  # 处理POST请求
	  if ($protocol =~ /^POST/) {
	    unless (-d $filename) {
	      # 500;
	      return;
	    }

	    # content长度
	    my $content_len = $headers->{"Content-Length"};
	    return unless $content_len;
	    my $bytes_read = 0;
	    my $boundary = <$client>;
	    scalar <$client> for (1 .. 2);
	    (my $upload_filename = <$client>) =~ s#\r\n$##;
	    scalar <$client> for (1 .. 8);
	    use bytes;
	    open my $fh, ">", "$filename/$upload_filename";
	    my $precede_line = <$client>;
	    while (1) {
	      my $follow_line = <$client>;
	      if ($follow_line eq $boundary) {
		$precede_line =~ s#\r\n$##;
		print $fh $precede_line;
		last;
	      }
	      print $fh $precede_line;
	      $precede_line = $follow_line;
	    }
	    no bytes;
	    close $fh;

	    my $response = "HTTP/1.1 200 OK$CRLF";
	    $response .= "Content-Type: " . "text/plain" . "$CRLF";
	    $response .= "Content-Length: " . 2 . "$CRLF";
	    my $old_locale = setlocale(LC_TIME, "en_US.utf-8");
	    $response .= "Date: " . (strftime "%a, %d %b %Y %T", gmtime) . " GMT$CRLF";
	    setlocale(LC_TIME, $old_locale);
	    $response .= "Last-Modified: Tue, 02 Jun 2009 11:03:57 GMT$CRLF";
	    $response .= "Server: lulu_simple_http_server/1.0.0$CRLF";
	    $response .= "$CRLF";
	    $response .= "OK";
	    print $client $response;
	    close $client;
	  } elsif ($protocol =~ /^GET/) {
	    if ($filename =~ m#^\W*$uuid#o) {
	      $filename = "/tmp/" . $filename;
	      
	    }
	    if (-f $filename) {
	      my($file_size) = (stat $filename)[7];
	      my $response = "HTTP/1.1 200 OK$CRLF";
	      $response .= "Content-Type: " . guess_media_type($filename) . "$CRLF";
	      $response .= "Content-Length: " . $file_size . "$CRLF";
	      my $old_locale = setlocale(LC_TIME, "en_US.utf-8");
	      $response .= "Date: " . (strftime "%a, %d %b %Y %T", gmtime) . " GMT$CRLF";
	      setlocale(LC_TIME, $old_locale);
	      $response .= "Last-Modified: Tue, 02 Jun 2009 11:03:57 GMT$CRLF";
	      $response .= "Server: lulu_simple_http_server/1.0.0$CRLF";
	      $response .= "$CRLF";
	      print $client $response;
	      open my($fh), $filename;
	      binmode $fh;
	      my $buf = "";
	      my $n;
	      while ($n = sysread($fh, $buf, 8*1024)) {
		last unless $n;
		die "sasa" unless syswrite $client, $buf;
	      }
	      close $fh;
	      
	    } elsif (-d $filename) {
	      
	      if ($quest_string =~ /zipdownload=1/) {
		my($basename, $dirname);
		$basename = basename $filename;
		$dirname = dirname $filename;
		my $response = "HTTP/1.1 200 OK$CRLF";
		$response .= "Content-Type: " . "application/zip" . "$CRLF";
		$response .= "Content-Disposition: attachment; file=\"${basename}.zip\"";
		my $old_locale = setlocale(LC_TIME, "en_US.utf-8");
		$response .= "Date: " . (strftime "%a, %d %b %Y %T", gmtime) . " GMT$CRLF";
		setlocale(LC_TIME, $old_locale);
		$response .= "Last-Modified: Tue, 02 Jun 2009 11:03:57 GMT$CRLF";
		$response .= "Server: lulu_simple_http_server/1.0.0$CRLF";
		$response .= "$CRLF";
		print $client $response;
		my $pwd = $ENV{PWD};
		chdir $dirname;
		open my($fh), "zip -q -0 -r - $basename |";
		binmode $fh;
		my $buf = "";
		my $n;
		while ($n = sysread($fh, $buf, 8*1024)) {
		  last unless $n;
		  die "sasa" unless syswrite $client, $buf;
		}
		close $fh;
		chdir $pwd;
	      } else {	    
		my $html = $html_1 . "      'script'    : '$req_path'," . $html_11;
		opendir my ($dirh), $filename;
		$filename =~ s#/$##;
		$filename = decode "utf8", $filename;
		my $file_count = 0;
		for (sort {$a cmp $b} readdir $dirh) {
		  next if ! $show_all_files && $_ =~ /^\..*/ && $_ ne "..";
		  next if $_ eq ".";
		  $file_count++;
		  $_ = decode "utf8", $_;
		  (my $display_filename = $_) =~ s#^(.{14}).*#$1...#;
		  $html .= "<tr valign='center'>";
		  if ("$_" eq "..") {
		    if ($filename !~ m#^./?$#) {
			$html .= <<"EOF";
      <td valign='middle' style='height: 50px; font-family: Chalkboard, Monaco, Courier;
  font-size: 24px; text-shadow: 0px 1px 0px white;overflow: hidden;'>
	<a href='/$filename/$_' style='color:
  green'>&nbsp;&nbsp;回到上一层目录</a>
      </td>
EOF
		      }
		  } elsif (-d "$filename/$_") {
		    #$html .= qq(<a href="/$filename/$_">$_</a>&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp<a href="/$filename/$_?zipdownload=1">Download ZIP file</a>);		  
		    $html .= << "EOF";
      <td valign='middle' style='height: 50px; font-family: Chalkboard, Monaco, Courier;
  font-size: 24px; text-shadow: 0px 1px 0px #000000;overflow: hidden;'>
	<a href='/$filename/$_' style='color:
  #EA7526' title='$_'>&nbsp;&nbsp;$display_filename</a>
      </td>
<td valign='middle' align='right'>
	<span style='font-size: 16px; color: green'>&nbsp;</span>
      </td>
      <td valign='middle' align='right' style='height: 50px; font-family: Chalkboard, Monaco, Courier;
  font-size: 24px; text-shadow: 0px 1px 0px #000000;'>
	<img
  style='height: 40px; cursor: pointer;' src='/D24EC059-2F1A-4848-B7A8-81A31383082F/zip_btn.png'
  onclick='if(confirm(\"您确定要打包下载 $_ 目录吗?\")){document.location=\"/$filename/$_?zipdownload=1\"}'></img>
      </td>
EOF
		  } else {
		    my $file_size = (stat "$filename/$_")[7];
		    if ($file_size < 1024) {
		      $file_size = "$file_size B";
		    } elsif ($file_size < 1048576) {
		      $file_size = sprintf "%.1fK", ($file_size / 1024);
		    } elsif ($file_size < 1073741824) {
		      $file_size = sprintf "%0.1fM", ($file_size / 1048576);
		    } elsif ($file_size < 2162516033536) {
		      $file_size = sprintf "%0.1fG", ($file_size / 1073741824);
		    }
		    
		    $html .= << "EOF2";
      <td valign='middle' style='height: 50px; font-family: Chalkboard, Monaco, Courier;
  font-size: 24px; text-shadow: 0px 1px 0px #000000;overflow: hidden;'>
	<a href='/$filename/$_' style='color:
  #F4DA3E' title='$_'>&nbsp;&nbsp;$display_filename</a>
      </td>
<td valign='middle' align='right'>
	<span style='font-size: 16px; color: green'>$file_size</span>
      </td>
      <td valign='middle' align='right' style='height: 50px; font-family: Chalkboard, Monaco, Courier;
  font-size: 24px; text-shadow: 0px 1px 0px #000000;'>
      </td>
EOF2

		  }
		  $html .= "</tr>";
		}
		if ($filename =~ /^\.\/?$/) {
		  $html .= $html_2 . "  <a id='show_upload_box' href='#upload' title='上传文件至根目录'>" . $html_22;
		} else {
		  $html .= $html_2 . "  <a id='show_upload_box' href='#upload' title='上传文件至 " . basename($filename) . " 目录'>" . $html_22;		  
		}
		$html .= "<script>";
		my $row_num = $file_count - (($filename =~ m#^./?$#) ? 1 : 0 );
		$html .= 'document.getElementById("container").style.height = ' . $row_num * 50 . ' + 403 + "px";';
		my $basename = basename $filename;
		$basename = "根目录" if $basename eq ".";
		$html .= 'document.getElementById("title").innerHTML="' . $basename . '";';
		$html .= "if (navigator.userAgent.match(/ie/)){window.location='/$uuid/noie.html'}";
		$html .= "</script>";
		$html .= "</html>";
		my $response = "HTTP/1.1 200 OK$CRLF";
		$response .= "Content-Type: text/html$CRLF";
		use bytes;
		$response .= "Content-Length: " . (length $html) . "$CRLF";
		no bytes;
		my $old_locale = setlocale(LC_TIME, "en_US.utf-8");
		$response .= "Date: " . (strftime "%a, %d %b %Y %T", gmtime) . " GMT$CRLF";
		setlocale(LC_TIME, $old_locale);
		$response .= "Connection: close$CRLF";
		$response .= "Server: lulu_simple_http_server/1.0.0$CRLF";
		$response .= "$CRLF";
		$response .= $html;
		
		print $client encode("utf8", $response);	      
		
	      }	      
	    } else {
	      #404
	    }
	  }
	  close $client;
	}, $client)->detach;
}

__DATA__
