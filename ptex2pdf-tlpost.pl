# ptex2pdf-tlpost.pl
#
# post action for ptex2pdf in TeX Live
# action carried out:
# - if the environment is Japanese or the installer is running in Japanese, then...
# - check for TeXworks tools.ini in
#   TW_INIPATH/configuration/tools.ini
# - if *not* available, initialize from the default plus Japanese stuff
# - if       available, read and try to add Japanese entries if not already there
#
# Copyright 2016 Norbert Preining
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
    'name' => 'upTeX (ptex2pdf)',
    'program' => 'ptex2pdf',
    'arguments' => '-u, -ot, $synctexoption, $fullname',
    'showPdf' => 'true'
  },
  '4' => {
    'name' => 'upLaTeX (ptex2pdf)',
    'program' => 'ptex2pdf',
    'arguments' => '-u, -l, -ot, $synctexoption, $fullname',
    'showPdf' => 'true'
  },
  '5' => {
    'name' => 'pBibTeX (Japanese BibTeX)',
    'program' => 'pbibtex',
    'arguments' => '$basename',
    'showPdf' => 'false'
  },
  '6' => {
    'name' => 'upBibTeX (Unicode pBibTeX)',
    'program' => 'upbibtex',
    'arguments' => '$basename',
    'showPdf' => 'false'
  },
  '7' => {
    'name' => 'mendex (Japanese MakeIndex)',
    'program' => 'mendex',
    'arguments' => '$basename',
    'showPdf' => 'false'
  },
  '8' => {
    'name' => 'upmendex (Unicode mendex)',
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

if ($::lang ne 'ja') {
  # not adjusting TeXworks for ptex2pdf
  exit(0);
}

$::lang = "C";
require TeXLive::TLWinGoo;
require("TeXLive/trans.pl");
#use Data::Dumper;

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
  # on Windows: we assume that the TL internal TeXWorks is used and
  #   search in TW_INIPATH
  # all other: we assume a system-wide TeXworks and use ~/.TeXworks
  my $toolsdir;
  if (win32()) {
    chomp( my $twini = `kpsewhich -var-value=TW_INIPATH` ) ;
    $toolsdir = "$twini/configuration";
  } else {
    $toolsdir = $ENV{'HOME'} . "/.TeXworks/configuration";
  }
  my $tools = "$toolsdir/tools.ini";
  my $highest_entry = 0;
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
        info("ptex2pdf programs already included in tools.ini, not adding again.\n");
        return 0;
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
  for my $t (sort keys %ptex2pdf) {
    my $id = sprintf("%03d", ++$highest_entry);
    $entries{$id} = $ptex2pdf{$t};
    if (win32()) {
      $entries{$id}{'program'} .= ".exe";
    }
  }
  my $fh;
  if (!open ($fh, ">", $tools)) {
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
  return 0;
}

### Local Variables:
### perl-indent-level: 2
### tab-width: 2
### indent-tabs-mode: nil
### End:
# vim:set tabstop=2 expandtab: #
