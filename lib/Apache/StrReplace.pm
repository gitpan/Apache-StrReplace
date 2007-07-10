package Apache::StrReplace;

use strict;
use warnings;
use vars qw(@ISA);

$Apache::StrReplace::VERSION = '0.01';

BEGIN {

  if ( exists $ENV{'MOD_PERL_API_VERSION'} && $ENV{'MOD_PERL_API_VERSION'} eq 2 ) {
    require Apache2::Filter;
    push @ISA, 'Apache2::Filter';
    require Apache2::Response;
    require Apache2::Const;
    require Apache2::RequestRec;
    require Apache2::RequestUtil;
    Apache2::Const->import(qw(OK DECLINED));
  } else {
    require Apache::Filter;
    push @ISA, 'Apache::Filter';
    require Apache::Response;
    require Apache::Const;
    require Apache::RequestRec;
    require Apache::RequestUtil;
    Apache::Const->import(qw(OK DECLINED));
  }
}

use constant BUFF_LEN => 1024;

sub handler {
  my $f = shift;

  unless ($f->r->content_type =~/text\/html/) {
    return DECLINED(); 
  }

  unless ( $f->ctx ) {
    $f->ctx( { body => '' } );
  }

  while ($f->read(my $buffer, BUFF_LEN)) {
    $f->ctx->{'body'}.= $buffer;
  }

  unless ($f->seen_eos) {
    return OK();
  }

  my $search  = $f->r->dir_config('StrReplaceSearch');
  my $replace = $f->r->dir_config('StrReplaceReplace');
  my $option  = $f->r->dir_config('StrReplaceOption') || 'g';

  eval '$f->ctx->{body}=~s/$search/'."$replace/$option;";

  $f->r->set_content_length( length( $f->ctx->{'body'} ) );

  $f->print( $f->ctx->{'body'} );

  OK();
}

1;
__END__

=head1 NAME

Apache::StrReplace - Filter between string replace

=head1 SYNOPSIS

Apache httpd.conf

    PerlModule Apache::StrReplace
    PerlSetVar StrReplaceSearch replace_before_string
    PerlSetVar StrReplaceReplace replace_after_string
    PerlSetVar StrReplaceOption replace_option
    PerlOutputFilterHandler Apache::StrReplace

=head1 DESCRIPTION

StrReplaceSearch ... search strings.
StrReplaceReplace ... replace strings.
StrReplaceOption ... replace options. ( default "g" )

run code.
    eval qq{ $string=~s/$search/$replace/$option; };

=head1 EXAMPLE

simple replace.

    PerlModule Apache::StrReplace
    PerlSetVar StrReplaceSearch hoge
    PerlSetVar StrReplaceReplace foo
    PerlOutputFilterHandler Apache::StrReplace

The numbered match variables.

    PerlModule Apache::StrReplace
    PerlSetVar StrReplaceSearch "([a-z]*).example.com"
    PerlSetVar StrReplaceReplace "dev.$1.example.com"
    PerlOutputFilterHandler Apache::StrReplace

Perl code.

    PerlModule Apache::StrReplace
    PerlSetVar StrReplaceSearch "<taxes>(\d+)</taxes>"
    PerlSetVar StrReplaceReplace "int( $1 * 1.05 )"
    PerlSetVar StrReplaceOption "eg"
    PerlOutputFilterHandler Apache::StrReplace

=head1 SEE ALSO

L<Apache2>, L<Apache2::Filter>

=head1 AUTHOR

Shinichiro Aska, E<lt>cpan@aska-tech.jpE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Shinichiro Aska

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
