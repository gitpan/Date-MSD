=head1 NAME

Date::MSD - conversion between flavours of Mars Sol Date

=head1 SYNOPSIS

	use Date::MSD qw(js_to_msd msd_to_cmsdn cmsdn_to_js);

	$msd = js_to_msd($js);
	($cmsdn, $cmsdf) = msd_to_cmsdn($msd, $tz);
	$js = cmsdn_to_js($cmsdn, $cmsdf, $tz);

	# and 33 other conversion functions

=head1 DESCRIPTION

For date and time calculations it is convenient to represent dates by
a simple linear count of days, rather than in a particular calendar.
This module performs conversions between different flavours of linear
count of Martian solar days ("sols").

Among Martian day count systems there are also some non-trivial
differences of concept.  There are systems that count only complete days,
and those that count fractional days also.  There are some that are fixed
to Airy Mean Time (time on the Martian prime meridian), and others that
are interpreted according to a timezone.  The functions of this module
appropriately handle the semantics of all the non-trivial conversions.

The day count systems supported by this module are Mars Sol Date,
Julian Sol, and Chronological Mars Solar Date, each in both integral
and fractional forms.

=head2 Flavours of day count

In the interests of orthogonality, all flavours of day count come in
both integral and fractional varieties.  Generally, there is a quantity
named "XYZ" which is a real count of days since a particular epoch (an
integer plus a fraction) and a corresponding quantity named "XYZN" ("XYZ
Number") which is a count of complete days since the same epoch.  XYZN is
the integral part of XYZ.  There is also a quantity named "XYZF" ("XYZ
Fraction") which is a count of fractional days since the XYZN changed.
XYZF is the fractional part of XYZ, in the range [0, 1).  This quantity
naming pattern is derived from the naming of Terran day counts.

All calendar dates given are in the Darian calendar for Mars.  An hour
number is appended to each date, separated by a "T"; hour 00 is midnight
at the start of the day.  An appended "Z" indicates that the date is to
be interpreted in the timezone of the prime meridian (Airy Mean Time),
and so is absolute; where any other timezone is to be used then this is
explicitly noted.

=over

=item MSD (Mars Sol Date)

days elapsed since 0140-19-26T00Z (approximately MJD 5521.50
in Terrestrial Time).  This epoch is the most recent near
coincidence of midnight on the Martian prime meridian with noon
on the Terran prime meridian.  MSD is defined by the paper at
L<http://pubs.giss.nasa.gov/docs/2000/2000_Allison_McEwen.pdf>.

=item JS (Julian Sol)

days elapsed since 0000-01-01T00Z (MSD -94129.0) (approximately
MJD -91195.22 in Terrestrial Time).  This epoch is an Airy
midnight approximating the last northward equinox prior to
the first telescopic observations of Mars.  The same epoch is
used for the Darian calendar for Mars.  JS is defined (but not
explicitly) by the document describing the Darian calendar, at
L<http://pweb.jps.net/~tgangale/mars/converter/calendar_clock.htm>.

=item CMSD (Chronological Mars Solar Date)

days elapsed since -0608-23-20T00 in the timezone of interest.
CMSD = MSD + 500000.0 + Zoff, where Zoff is the timezone
offset in fractional days.  CMSD is defined by the memo at
L<http://www.fysh.org/~zefram/time/define_cmsd.txt>.

=back

=head2 Meaning of the day

A day count has meaning only in the context of a particular definition
of "day".  Potentially several time scales could be expressed in terms
of a day count, just as Terran day counts such as MJD are used in the
timescales UT1, UT2, UTC, TAI, TT, TCG, and others.  For a day number
to be meaningful it is necessary to be aware of which kind of day it
is counting.  Conversion between the different time scales is out of
scope for this module.

=cut

package Date::MSD;

use warnings;
use strict;

use Carp qw(croak);

our $VERSION = "0.000";

use base "Exporter";
our @EXPORT_OK;

my %msd_flavours = (
	msd => { epoch_msd => 0 },
	js => { epoch_msd => -94129.0 },
	cmsd => { epoch_msd => -500000.0, zone => 1 },
);

=head1 FUNCTIONS

Day counts in this API may be native Perl numbers or C<Math::BigRat>
objects.  Both are acceptable for all parameters, in any combination.
In all conversion functions, the result is of the same type as the
input, provided that the inputs are of consistent type.  If native Perl
numbers are supplied then the conversion is subject to floating point
rounding, and possible overflow if the numbers are extremely large.
The use of C<Math::BigRat> is recommended to avoid these problems.
With C<Math::BigRat> the results are exact.

There are conversion functions between all pairs of day count systems.
This is a total of 36 conversion functions (including 6 identity
functions).

When converting between timezone-relative counts (CMSD) and absolute
counts (MSD, JS), the timezone that is being used must be specified.
It is given in a ZONE argument as a fractional number of days offset
from the base time scale (typically Airy Mean Time).  Beware of
floating point rounding when the offset does not have a terminating
binary representation; use of C<Math::BigRat> avoids this problem.
A ZONE parameter is not used when converting between absolute day counts
(e.g., between MSD and JS) or between timezone-relative counts (e.g.,
between CMSD and CMSDN).

=over

=item msd_to_msd(MSD)

=item msd_to_js(MSD)

=item msd_to_cmsd(MSD, ZONE)

=item js_to_msd(JS)

=item js_to_js(JS)

=item js_to_cmsd(JS, ZONE)

=item cmsd_to_msd(CMSD, ZONE)

=item cmsd_to_js(CMSD, ZONE)

=item cmsd_to_cmsd(CMSD)

Conversions between fractional day counts principally involve a change
of epoch.  The input identifies a point in time, as a fractional day
count of input flavour.  The function returns the same point in time,
represented as a fractional day count of output flavour.

=item msd_to_msdn(MSD)

=item msd_to_jsn(MSD)

=item msd_to_cmsdn(MSD, ZONE)

=item js_to_msdn(JS)

=item js_to_jsn(JS)

=item js_to_cmsdn(JS, ZONE)

=item cmsd_to_msdn(CMSD, ZONE)

=item cmsd_to_jsn(CMSD, ZONE)

=item cmsd_to_cmsdn(CMSD)

These conversion functions go from a fractional count to an integral
count.  The input identifies a point in time, as a fractional day count of
input flavour.  The function determines the day number of output flavour
that applies at that instant.  In scalar context only this integral day
number is returned.  In list context a list of two values is returned:
the integral day number and the day fraction in the range [0, 1).
The day fraction, representing the time of day, is relative to midnight.

=item msdn_to_msd(MSDN, MSDF)

=item msdn_to_js(MSDN, MSDF)

=item msdn_to_cmsd(MSDN, MSDF, ZONE)

=item jsn_to_msd(JSN, JSF)

=item jsn_to_js(JSN, JSF)

=item jsn_to_cmsd(JSN, JSF, ZONE)

=item cmsdn_to_msd(CMSDN, CMSDF, ZONE)

=item cmsdn_to_js(CMSDN, CMSDF, ZONE)

=item cmsdn_to_cmsd(CMSDN, CMSDF)

These conversion functions go from an integral count to a fractional
count.  The input identifies a point in time, as an integral day number of
input flavour plus day fraction in the range [0, 1).  The day fraction,
representing the time of day, is relative to midnight.  The identified
point in time is returned in the form of a fractional day number of
output flavour.

=item msdn_to_msdn(MSDN[, MSDF])

=item msdn_to_jsn(MSDN[, MSDF])

=item msdn_to_cmsdn(MSDN, MSDF, ZONE)

=item jsn_to_msdn(JSN[, JSF])

=item jsn_to_jsn(JSN[, JSF])

=item jsn_to_cmsdn(JSN, JSF, ZONE)

=item cmsdn_to_msdn(CMSDN, CMSDF, ZONE)

=item cmsdn_to_jsn(CMSDN, CMSDF, ZONE)

=item cmsdn_to_cmsdn(CMSDN[, CMSDF])

These conversion functions go from an integral count to another integral
count.  They can be used either to convert only a day number or to convert
a point in time using integer-plus-fraction form.  The output convention
is identical to that for C<msd_to_msdn> et al, including the variation
depending on calling context.

If converting a point in time, the input identifies it as an integral
day number of input flavour plus day fraction in the range [0, 1).
The day fraction, representing the time of day, is relative to midnight.
The same point in time is (in list context) returned as a list of integral
day number of output flavour and the day fraction in the range [0, 1).

If it is desired only to convert integral day numbers, it is still
necessary to consider time of day, because in the general case the days
are delimited differently by the input and output day count flavours.
A day fraction must be specified if there is such a difference, and
the conversion is calculated for the point in time thus identified.
To perform a conversion for a large part of the day, give a representative
time of day within it.  If converting between systems that delimit days
identically (e.g., between MSD and JS), the day fraction is optional
and defaults to zero.

=cut

eval {
	require POSIX;
	*floor = \&POSIX::floor;
};
if($@ ne "") {
	*floor = sub($) {
		my $i = int($_[0]);
		return $i == $_[0] || $_[0] > 0 ? $i : $i - 1;
	}
}

sub check_dn($$) {
	croak "purported day number $_[0] is not an integer"
		unless ref($_[0]) ? $_[0]->is_int : $_[0] == int($_[0]);
	croak "purported day fraction $_[1] is out of range [0, 1)"
		unless $_[1] >= 0 && $_[1] < 1;
}

sub ret_dn($) {
	my $dn = ref($_[0]) eq "Math::BigRat" ?
			$_[0]->copy->bfloor : floor($_[0]);
	return wantarray ? ($dn, $_[0] - $dn) : $dn;
}

foreach my $src (keys %msd_flavours) { foreach my $dst (keys %msd_flavours) {
	my $ediff = $msd_flavours{$src}->{epoch_msd} -
			$msd_flavours{$dst}->{epoch_msd};
	my $ediffh = $ediff == int($ediff) ? 0 : 0.5;
	my $ediffi = $ediff - $ediffh;
	my $src_zone = !!$msd_flavours{$src}->{zone};
	my $dst_zone = !!$msd_flavours{$dst}->{zone};
	my($zp, $z1, $z2);
	if($src_zone == $dst_zone) {
		$zp = $z1 = $z2 = "";
	} else {
		$zp = "\$";
		my $zsign = $src_zone ? "-" : "+";
		$z1 = "$zsign \$_[1]";
		$z2 = "$zsign \$_[2]";
	}
	eval "sub ${src}_to_${dst}(\$${zp}) { \$_[0] + (${ediff}) ${z1} }";
	push @EXPORT_OK, "${src}_to_${dst}";
	eval "sub ${src}_to_${dst}n(\$${zp}) {
		ret_dn(\$_[0] + (${ediff}) ${z1})
	}";
	push @EXPORT_OK, "${src}_to_${dst}n";
	eval "sub ${src}n_to_${dst}(\$\$${zp}) {
		check_dn(\$_[0], \$_[1]);
		\$_[0] + \$_[1] + (${ediff}) ${z2}
	}";
	push @EXPORT_OK, "${src}n_to_${dst}";
	my($tp, $tc);
	if($ediffh == 0 && $src_zone == $dst_zone) {
		$tp = ";";
		$tc = "push \@_, 0 if \@_ == 1;";
	} else {
		$tp = $tc = "";
	}
	eval "sub ${src}n_to_${dst}n(\$${tp}\$${zp}) { $tc
		check_dn(\$_[0], \$_[1]);
		ret_dn(\$_[0] + \$_[1] + ($ediff) ${z2})
	}";
	push @EXPORT_OK, "${src}n_to_${dst}n";
} }

=back

=head1 SEE ALSO

L<Date::Darian::Mars>,
L<Date::JD>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2007 Andrew Main (Zefram) <zefram@fysh.org>

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
