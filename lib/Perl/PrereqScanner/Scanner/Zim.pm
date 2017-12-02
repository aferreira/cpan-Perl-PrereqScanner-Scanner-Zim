
use 5.010;
use strict;
use warnings;

package Perl::PrereqScanner::Scanner::Zim;

# ABSTRACT: Scan for modules loaded with Importer::Zim

use Moose;
with 'Perl::PrereqScanner::Scanner';

use PPIx::Literal ();

sub scan_for_prereqs {
    my ( $self, $ppi_doc, $req ) = @_;

    # regular use, require, and no
    my $includes = $ppi_doc->find('Statement::Include') || [];
    for my $node (@$includes) {

        if ( $self->_is_base_module( $node->module ) ) {

            my @args = PPIx::Literal->convert( $node->arguments );

            if (@args) {
                my $module = shift @args;
                my $opts = ref $args[0] eq 'HASH' ? shift @args : {};
                my $version =
                  exists $opts->{-version} ? $opts->{-version} : '0';
                $req->add_minimum( $module => $version );
            }
        }
    }
}

sub _is_base_module {
    state $IS_BASE = {
        map { $_ => 1 }
          qw(
          zim
          Importer::Zim
          Importer::Zim::Lexical
          Importer::Zim::EndOfScope
          Importer::Zim::Unit
          Importer::Zim::Bogus
          )
    };
    return $IS_BASE->{ $_[1] };
}

1;

=encoding utf8

=head1 SYNOPSIS

    use Perl::PrereqScanner;
    my $scanner = Perl::PrereqScanner->new( { extra_scanners => ['Zim'] } );
    my $prereqs = $scanner->scan_ppi_document($ppi_doc);
    my $prereqs = $scanner->scan_file($file_path);
    my $prereqs = $scanner->scan_string($perl_code);
    my $prereqs = $scanner->scan_module($module_name);

=head1 DESCRIPTION

This scanner will look for dependencies from the L<Importer::Zim> module:

    use zim 'Carp' => 'croak';

    use Importer::Zim 'Scalar::Util' => qw(blessed);

    use zim 'Test::More' => { -version => 0.88 } => qw(ok done_testing);
