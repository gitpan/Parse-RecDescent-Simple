package Parse::RecDescent::Simple;

use warnings;
use strict;
use Parse::RecDescent;
use XML::xmlapi;

=head1 NAME

Parse::RecDescent::Simple - Quick and dirty use of the excellent Parse::RecDescent if you just want a simple tree structure

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

I I<love> C<Parse:RecDescent>, but I don't love writing the callback code for every stupid little thing I write, and I really don't
love the overcomplicated structure you get back from autotree mode.  So this module uses L<XML::xmlapi> (a structure manipulation
module of my own authorship that bears, at this juncture, only a fleeting relation to XML-specific usage) to produce a simple tree structure
based on the recursive descent parser specification you pass it.

This structure does I<not> bless tree nodes into classes; you can do that yourself.  It doesn't preserve information about which branch
of a rule is selected, either.  The name of each node will correspond to the rule name in the parser that sanctioned it.

I originally started dabbling in Parse::RecDescent when I wanted to parse strings like this:
    dialog (parameter, parameter) [option, option] "title"
Here, the function word is mandatory, while the parameter list (which parameterizes the dialog), the option list (which determines
how the dialog fits into its parent, not shown), and the title are all optional.  I used to write string manipulation routines - badly -
to handle this kind of thing, and this year I finally got fed up with it.  Parse::RecDescent is the obvious answer.

But Parse::RecDescent has too damn many options.  All I want is to grab the stuff you see up there.  The <autotree> directive kinda sorta
gives me something like what I want, but it rapidly gets too difficult to extract the good stuff as soon as the grammar has any alternate
subrules, because each alternate subrule is reflected in the output structure.  I<Not> what I want.  Hence this.

The grammar I want for the line above is pretty simple:

    line: word parmlist(?) optionlist(?) label(?) colon(?)
    colon: ":"
    parmlist: "(" option(s /,\s*|\s+/) ")"
    optionlist: "[" option(s /,\s*|\s+/) "]"
    label: <perl_quotelike>
    word: /[A-Za-z0-9_\-]+/
    option: /[A-Za-z0-9_\- ]+/ | <perl_quotelike>
	
The <perl_quotelike> directive rocks my world, by the way.  Anyway, we'd use that grammar as follows:

    use Parse::RecDescent::Simple;

    my $parser = Parse::RecDescent::Simple->new(q{
	    parse: line
	    line: word parmlist(?) optionlist(?) label(?) colon(?)
        colon: ":"
        parmlist: "(" option(s /,\s*|\s+/) ")"
        optionlist: "[" option(s /,\s*|\s+/) "]"
        label: <perl_quotelike>
        word: /[A-Za-z0-9_\-]+/
        option: /[A-Za-z0-9_\- ]+/ | <perl_quotelike>
	});
	
	my $parse = $parser->parse("this (is, a) ['test, ing', of all] \"this stuff\"");
	print $parse->string() . "\n";
	
This just prints the XML representation of the parse tree for the string passed, and it returns this if all goes well:

   <line>
   <word>this</word>
   <parmlist>(
   <option>is</option>
   <option>a</option>
   )</parmlist>
   <optionlist>[
   <option>test, ing</option>
   <option>of all</option>
   ]</optionlist>
   <label>this stuff</label>
   </line>
   
There are obviously a lot of things that could be improved to make this more flexible, but let's face it - this already gives me
everything I need today.  Perhaps it will help you, too.  And frankly, it's about twenty lines of Perl and two hours invested making
it something that works - it's just that it's two hours I'll never have to spend again, unlike every other time I've wanted to do
something with Parse::RecDescent.

=head1 SUBROUTINES/METHODS

=head2 new(specification)

Creates a new parser object based on the specification you pass.  Version 0.1 B<requires> that one rule is named 'parse'; that is the rule
that will be called.  Very Nasty Errors will occur if you forget this.  If parse just fronts for another rule, though, the topmost tag will
be named for the other rule, so it all kind of makes sense in the end.

=cut

sub new {
   my ($class, $specification, $parameters) = @_;
   $parameters = {} unless ref $parameters eq 'HASH';
   my $self = bless $parameters, $class;
   $self->{specification} = $specification;
   $::RD_AUTOACTION = q{ { $self->{_upper}->process (@item); } };
   #$::RD_HINT = 1;
   $self->{rd} = Parse::RecDescent->new ($specification);
   $self->{rd}->{_upper} = $self;
}

=head2 parse($string)

Given a parser object you created earlier, parses the string you pass into an XML::xmlapi structure.

=cut

sub parse { $_[0]->{rd}->parse($_[1]); }

=head2 process(@item)

Called by C<Parse::RecDescent> during parsing.  This part you could actually override if you wanted to subclass.

=cut

sub process {
   my $self = shift;
   my $tag = shift;

   return $_[0] if (@_ eq 1 and ref $_[0] eq 'XML::xmlapi');

   my $return = XML::xmlapi->create ($tag);
   if (@_ eq 1 and ref $_[0] eq 'ARRAY' and ${$_[0]}[0] eq '') {
      $return->append(XML::xmlapi->createtext (${$_[0]}[2]));
   } else {
      foreach (@_) {
         if (ref $_ eq 'ARRAY') {
	        foreach (@$_) {
		       $return->append_pretty($_);
   		    }
	     } elsif (ref $_ eq 'XML::xmlapi') {
	        $return->append_pretty ($_);
	     } else {
	        $return->append(XML::xmlapi->createtext ($_));
		 }
      }
   }
   #print $return->string() . "\n";
   return $return;
}

=head1 AUTHOR

Michael Roberts, C<< <michael at vivtek.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-parse-recdescent-simple at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Parse-RecDescent-Simple>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

Let me assure you, I<there will be bugs>.  I haven't even started to write a hundredth of the test cases this should actually be run through.
It will stop silently mid-parse and give you perfectly legitimate-looking results if things don't match later; it will fail in horrible and unexpected ways 
on perfectly reasonable grammars; it won't really do what you expect, unless you expect it to do what I intended it to do today.  You've
been warned.  That said, please send me your grammars and what you expected them to do; the Muse willing, I will write up test cases and
(someday) make them work.  Or send money.  The Muse is sometimes convinced by money, and it's worth a try.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Parse::RecDescent::Simple


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Parse-RecDescent-Simple>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Parse-RecDescent-Simple>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Parse-RecDescent-Simple>

=item * Search CPAN

L<http://search.cpan.org/dist/Parse-RecDescent-Simple/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Michael Roberts.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Parse::RecDescent::Simple
