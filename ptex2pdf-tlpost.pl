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

my $texdir;
my $mode;

BEGIN {
  $^W = 1;
  $mode = lc($ARGV[0]);
  $texdir = $ARGV[1];
  # make Perl find our packages first:
  unshift (@INC, "$texdir/tlpkg");
}
use TeXLive::TLUtils qw(win32 mkdirhier conv_to_w32_path log info);

if ($mode eq 'install') {
  do_install();
} elsif ($mode eq 'remove') {
  do_remove();
} else {
  die("unknown mode: $mode\n");
}

sub do_remove {
  # do nothing
}

sub do_install {
  # how to find TeX Works
  # on Windows: we assume that the TL internal TeXWorks is used and
  #   search in TW_INIPATH
  # all other: we assume a system-wide TeXworks and use ~/.TeXworks
  my $tools;
  if (win32()) {
    chomp( my $twini = `kpsewhich -var-value=TW_INIPATH` ) ;
    $tools = "$twini/configuration/tools.ini";
  } else {
    $tools = $env{'HOME'} . "/.TeXworks/configuration/tools.ini";
  }
  if (-r $tools) {
    # assume that succeeds, we tested -r above!
    open (FOO, "<", $tools);
    my @lines = <FOO>;
    chomp(@lines);
    close(FOO);

  } else {
  }
  return 0;
}

### Local Variables:
### perl-indent-level: 2
### tab-width: 2
### indent-tabs-mode: nil
### End:
# vim:set tabstop=2 expandtab: #
