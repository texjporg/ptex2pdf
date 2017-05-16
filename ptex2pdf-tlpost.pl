# ptex2pdf-tlpost.pl
#
# post action for ptex2pdf in TeX Live
# action carried out:
# - if the environment is Japanese or the installer is running in Japanese, then...
#   - check for TeXworks tools.ini in
#     TW_INIPATH/configuration/tools.ini
#     - if *not* available, initialize from the default plus Japanese stuff
#     - if       available, read and try to add Japanese entries if not already there
#   - check for TeXworks.ini in
#     TW_INIPATH/TUG/TeXworks.ini
#     - if *not* available, initialize the default one with "pLaTeX (ptex2pdf)"
#     - if       available, read and try to set the default if not already there
#
# Copyright 2016-2017 Norbert Preining
# Copyright 2017 Japanese TeX Developer Community
# This file is licensed under the GNU General Public License version 2
# or any later version.
#
# TODO
# - what to do on remove?
#

my $texdir;
my $mode;

BEGIN {
  $^W = 1;
  $mode = lc($ARGV[0]);
  $texdir = $ARGV[1];
  # make Perl find our packages first:
  unshift (@INC, "$texdir/tlpkg");
}

use TeXLive::TLUtils qw(win32 mkdirhier conv_to_w32_path log info tlwarn);


my %ptex2pdf = (
  '1' => {
    'name' => 'pTeX (ptex2pdf)',
    'program' => 'ptex2pdf',
    'arguments' => '-ot, -kanji=utf8 $synctexoption, $fullname',
    'showPdf' => 'true'
  },
  '2' => {
    'name' => 'pLaTeX (ptex2pdf)',
    'program' => 'ptex2pdf',
    'arguments' => '-l, -ot, -kanji=utf8 $synctexoption, $fullname',
    'showPdf' => 'true'
  },
  '3' => {
    'name' => 'pBibTeX',
    'program' => 'pbibtex',
    'arguments' => '-kanji=utf8, $basename',
    'showPdf' => 'false'
  },
  '4' => {
    'name' => 'mendex',
    'program' => 'mendex',
    'arguments' => '-U, $basename',
    'showPdf' => 'false'
  },
  '5' => {
    'name' => 'upTeX (ptex2pdf)',
    'program' => 'ptex2pdf',
    'arguments' => '-u, -ot, $synctexoption, $fullname',
    'showPdf' => 'true'
  },
  '6' => {
    'name' => 'upLaTeX (ptex2pdf)',
    'program' => 'ptex2pdf',
    'arguments' => '-u, -l, -ot, $synctexoption, $fullname',
    'showPdf' => 'true'
  },
  '7' => {
    'name' => 'upBibTeX',
    'program' => 'upbibtex',
    'arguments' => '$basename',
    'showPdf' => 'false'
  },
  '8' => {
    'name' => 'upmendex',
    'program' => 'upmendex',
    'arguments' => '$basename',
    'showPdf' => 'false'
  },
);

#
# NEEDS TO BE KEPT IN SYNC WITH TEX WORKS compiled in default!
my %original = (
  '001' => {
    'name' => 'pdfTeX',
    'showPdf' => 'true',
    'program' => 'pdftex',
    'arguments' => '$synctexoption, $fullname'
  },
  '002' => {
    'name' => 'pdfLaTeX',
    'showPdf' => 'true',
    'program' => 'pdflatex',
    'arguments' => '$synctexoption, $fullname'
  },
  '003' => {
    'name' => 'LuaTeX',
    'showPdf' => 'true',
    'arguments' => '$synctexoption, $fullname',
    'program' => 'luatex'
  },
  '004' => {
    'showPdf' => 'true',
    'name' => 'LuaLaTeX',
    'program' => 'lualatex',
    'arguments' => '$synctexoption, $fullname'
  },
  '005' => {
    'program' => 'xetex',
    'arguments' => '$synctexoption, $fullname',
    'name' => 'XeTeX',
    'showPdf' => 'true'
  },
  '006' => {
    'arguments' => '$synctexoption, $fullname',
    'program' => 'xelatex',
    'name' => 'XeLaTeX',
    'showPdf' => 'true'
  },
  '007' => {
    'program' => 'context',
    'arguments' => '--synctex, $fullname',
    'name' => 'ConTeXt (LuaTeX)',
    'showPdf' => 'true'
  },
  '008' => {
    'showPdf' => 'true',
    'name' => 'ConTeXt (pdfTeX)',
    'arguments' => '--synctex, $fullname',
    'program' => 'texexec'
  },
  '009' => {
    'program' => 'texexec',
    'arguments' => '--synctex, --xtx, $fullname',
    'showPdf' => 'true',
    'name' => 'ConTeXt (XeTeX)'
  },
  '010' => {
    'arguments' => '$basename',
    'program' => 'bibtex',
    'name' => 'BibTeX',
    'showPdf' => 'false'
  },
  '011' => {
    'name' => 'MakeIndex',
    'showPdf' => 'false',
    'arguments' => '$basename',
    'program' => 'makeindex'
  },
);

$::lang = "C";
if (TeXLive::TLUtils::win32()) {
  require TeXLive::TLWinGoo;
}
require("TeXLive/trans.pl");
#use Data::Dumper;

if ($::lang ne 'ja') {
  # not adjusting TeXworks for ptex2pdf
  exit(0);
}

if ($mode eq 'install') {
  do_install();
} elsif ($mode eq 'remove') {
  do_remove();
} else {
  die("unknown mode: $mode\n");
}

sub do_remove {
  # TODO - what should we do here???
}

sub do_install {
  # how to find TeX Works
  # see http://doc.qt.io/qt-5/qsettings.html
  #
  # NativeFormat
  # ------------
  # Unix:
  #  $HOME/.config/TUG/TeXworks.conf
  #  $HOME/.config/TeXworks.conf
  #  /etc/xdg/TUG/TeXworks.conf
  #  /etc/xdg/TeXworks.conf
  # Mac:
  #  $HOME/Library/Preferences/org.tug.TeXworks.plist
  #  $HOME/Library/Preferences/com.TeXworks.plist
  #  /Library/Preferences/com.tug.TeXworks.plist
  #  /Library/Preferences/com.TeXworks.plist
  # Win:
  #  HKEY_CURRENT_USER\Software\TUG\TeXworks
  #  HKEY_CURRENT_USER\Software\TUG\OrganizationDefaults
  #  HKEY_LOCAL_MACHINE\Software\TUG\TeXworks
  #  HKEY_LOCAL_MACHINE\Software\TUG\OrganizationDefaults
  #
  # IniFormat
  # ---------
  # Unix/Mac/iOS:
  #  $HOME/.config/TUG/TeXworks.ini
  #  $HOME/.config/TeXworks.ini
  #  /etc/xdg/TUG/TeXworks.ini
  #  /etc/xdg/TeXworks.ini
  # Windows
  #  FOLDERID_RoamingAppData\TUG\TeXworks.ini
  #  FOLDERID_RoamingAppData\TUG.ini
  #  FOLDERID_ProgramData\TUG\TeXworks.ini
  #  FOLDERID_ProgramData\TUG.ini
  # where
  #  FOLDERID_RoamingAppData usually points to C:\Users\User Name\AppData\Roaming
  #  FOLDERID_ProgramData usually points to C:\ProgramData
  #
  # TeXworks uses a mixture of NativeFormat and IniFormat
  # ConfigurableApp::ConfigurableApp set NativeFormat
  # TWApp checking for portable mode uses IniFormat
  #
  # So my guess is:
  # - TeXworks as shipped in TL uses the portable app setup, thus IniFormat
  # - TeXworks on Mac/Unix (not distributed with TL) uses NativeFormat
  #
  my $toolsdir;
  my $tugdir;
  my $inifile;
  if (win32()) {
    # we assume TeXworks from TL, thus IniFormat
    chomp( my $twini = `kpsewhich -var-value=TW_INIPATH` ) ;
    $toolsdir = "$twini/configuration";
    $tugdir = "$twini/TUG";
    $inifile = "TeXworks.ini";
  } elsif ($^O eq "darwin") {
    $toolsdir = $ENV{'HOME'} . "/Library/TeXworks/configuration";
    $tugdir = $ENV{'HOME'} . "/Library/Preferences";
    $inifile = "org.tug.TeXworks.plist";
    # Just for completeness, as we are not doing adjustments to
    # default engines on Mac. For this plist access would ne necessary.
  } else {
    $toolsdir = $ENV{'HOME'} . "/.TeXworks/configuration";
    my $xdgconfhome = (defined($ENV{'XDG_CONFIG_HOME'}) ? $ENV{'XDG_CONFIG_HOME'} : $ENV{'HOME'} . "/.config");
    $tugdir = $xdgconfhome . "/TUG";
    $inifile = "TeXworks.conf";
  }
  # print "toolsdir = $toolsdir\n";
  # print "tugdir = $tugdir\n";
  my $tools = "$toolsdir/tools.ini";
  my $tug = "$tugdir/$inifile";
  my $highest_entry = 0;
  my $noadjust;
  my $found_platex;
  my $fh;
  #
  # check tools.ini
  $noadjust = 0;
  $found_platex = 0;
  if (-r $tools) {
    # assume that succeeds, we tested -r above!
    open (FOO, "<", $tools);
    my @lines = <FOO>;
    chomp(@lines);
    close(FOO);
    # policy: if ptex2pdf appears in any of the program entries, we
    # do nothing. Only otherwise we add new entries.
    my %entries;
    my $in_entry = 0;
    foreach my $l (@lines) {
      if ($l =~ m/^\[(.*)\]\s*$/) {
        $in_entry = $1;
        $highest_entry = ( (0+$in_entry) > $highest_entry ? (0+$in_entry) : $highest_entry);
        next;
      }
      if ($l =~ m/^\s*$/) {
        # empty line terminates entry
        $in_entry = 0;
        next;
      }
      if ($l =~ m/^([^=]*)=(.*)$/) {
        if ($in_entry) {
          $entries{$in_entry}{$1} = $2;
        } else {
          tlwarn("\nptex2pdf postaction: line outside of entry in $tools: $l\n");
        }
        next;
      }
      # we are still here
      tlwarn("\nptex2pdf postaction: unrecognized line in $tools: $l\n");
    }
    # $Data::Dumper::Indent = 1;
    # print Data::Dumper->Dump([\%entries], ["entries"]);
    # now check that we don't see ptex2pdf
    for my $id (keys %entries) {
      if ($entries{$id}{'program'} && $entries{$id}{'program'} =~ m/^ptex2pdf/s) {
        if (!$noadjust) { # this test reduces duplicate info below
          info("ptex2pdf programs already included in tools.ini, not adding again.\n");
          $noadjust = 1;
        }
        # no need for edit tools.ini, but still we need to check if
        # the exact string "pLaTeX (ptex2pdf)" is available,
        # to ensure success of setting it as the default
        if ($entries{$id}{'name'} =~ m/^pLaTeX \(ptex2pdf\)$/s) {
          $found_platex = 1;
        }
      }
    }
  } else {
    # no tools, we need to create the path and the file
    mkdirhier($toolsdir);
    for my $t (sort keys %original) {
      my $id = sprintf("%03d", ++$highest_entry);
      $entries{$id} = $original{$t};
      if (win32()) {
        $entries{$id}{'program'} .= ".exe";
      }
    }
  }
  # adjust tools.ini
  if (!$noadjust) {
    for my $t (sort keys %ptex2pdf) {
      my $id = sprintf("%03d", ++$highest_entry);
      $entries{$id} = $ptex2pdf{$t};
      if (win32()) {
        $entries{$id}{'program'} .= ".exe";
      }
    }
    if (!open ($fh, ">>", $tools)) {
      tlwarn("\nptex2pdf postaction: cannot update $tools!\n");
      return 1;
    }
    # we are in install mode in a line that will be finished with ...done 
    info("(ptex2pdf postinst: adjusting TeXworks tools.ini)");
    for my $k (sort keys %entries) {
      print $fh "[", $k, "]\n";
      for my $key (qw/name program arguments showPdf/) {
        print $fh $key, '=', $entries{$k}{$key}, "\n";
      }
      print $fh "\n";
    }
    close($fh) or tlwarn("\nptex2pdf postaction: cannot close $tools\n");
    # the exact string "pLaTeX (ptex2pdf)" is added by myself
    $found_platex = 1;
  }
  #
  # Setting defaults on Mac needs plist changes, nothing we can easily do, sorry.
  if ($^O eq "darwin") {
    info("(ptex2pdf postinst: default setting on Mac is currently unsupported)");
    return 0;
  }
  # check TeXworks.ini
  $noadjust = 0;
  if (-r $tug) {
    # assume that succeeds, we tested -r above!
    open (FOO, "<", $tug);
    my @lines = <FOO>;
    chomp(@lines);
    close(FOO);
    # policy: if defaultEngine appears in TeXworks.ini, we do nothing.
    # Only otherwise we set the value to "pLaTeX (ptex2pdf)".
    foreach my $l (@lines) {
      if ($l =~ m/^defaultEngine=(.*)$/) {
        $noadjust = $1;
      }
    }
    if ($noadjust) {
      info("default is already set as $noadjust in TeXworks.ini, no change.\n");
    }
  } else {
    # no TeXworks.ini, we need to create the path and the file
    mkdirhier($tugdir);
  }
  # adjust TeXworks.ini
  if (!$noadjust) {
    if (!open ($fh, ">>", $tug)) {
      tlwarn("\nptex2pdf postaction: cannot update $tug!\n");
      return 1;
    }
    # we are in install mode in a line that will be finished with ...done 
    if ($found_platex) {
      info("(ptex2pdf postinst: adjusting TeXworks.ini)");
      print $fh "defaultEngine=pLaTeX (ptex2pdf)\n";
    } else {
      tlwarn("\nptex2pdf postaction: \"pLaTeX (ptex2pdf)\" not found, exiting without setting default!\n");
      return 1;
    }
    close($fh) or tlwarn("\nptex2pdf postaction: cannot close $tug\n");
  }
  #
  # all done
  return 0;
}

### Local Variables:
### perl-indent-level: 2
### tab-width: 2
### indent-tabs-mode: nil
### End:
# vim:set tabstop=2 expandtab: #
