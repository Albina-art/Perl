use FindBin;
use DDP;
use lib "$FindBin::Bin/lib";
BEGIN{
	if ($] < 5.018) {
		package experimental;
		use warnings::register;
	}
}
no warnings 'experimental';
use Local::Source::Array;
use Local::Reducer::Sum;
use Local::Row::Simple;
use Local::Source::Text;
use Local::Reducer::MaxDiff;
use Local::Reducer::MinMaxAvg;
use Local::Row::JSON;
use Local::Row;
use Local::Source::FileHandler;
my $reducer = Local::Reducer::MaxDiff->new(
    top => 'received',
    bottom => 'sended',
    source => Local::Source::Array->new(array => [
         '{"received": 1,"sended": 2}',
         '{"sended": 2,"received": 4}',
         '{"received": 10,"sended": 2}',
         '{"sended": 200,"received": 4}',
     ]),
    row_class => 'Local::Row::JSON',    
    initial_value => 0,
);
p $reducer->{source};
$reducer->reduce_all;
print "reduce_all MaxDiff = ", $reducer->reduce_all();

# my $reducer = Local::Reducer::Sum->new(
#     field => 'price',
#     source => Local::Source::FileHandler->new(fh => '1.txt'),
#     row_class => 'Local::Row::JSON',
#     initial_value => 0,
# );
# p $reducer->{source};
# print "Sum reduce_n(2) = ", $reducer->reduce_n(2);
# print "Sum reduce_all = ", $reducer->reduce_all();

my $reducer = Local::Reducer::Sum->new(
    field => 'price',
    source => Local::Source::Array->new(array => [
        '{"price": 1}',
        '{"price": 2}',
        '{"price": 3}',
    ]),
    row_class => 'Local::Row::JSON',
    initial_value => 0,
);
p $reducer->{source};
print "Sum reduce_n(2) = ", $reducer->reduce_n(2);
print "Sum reduce_all = ", $reducer->reduce_all();

# my $reducer = Local::Reducer::MinMaxAvg->new(
#     field => 'price',
#     source => Local::Source::Array->new(array => [
#         '{"price": 4}',
#         '{"price": 144}',
#         '{"price": 777}',
#         '{"price": 57}',
#     ]),
#     row_class => Local::Row::JSON,
#     initial_value => undef,
# );
# p $reducer->{source};
# $reducer->reduce_all;
# print 'Min = ', $reducer->get_min; 
# print 'Max = ', $reducer->get_max; 


# my $reducer = Local::Reducer::MinMaxAvg->new(
#     field => 'price',
#     source => Local::Source::Array->new(array => [
#         '{"price": 1}',
#         '{"price": 2}',
#         '{"price": 3}',
#     ]),
#     row_class => Local::Row::JSON,
#     initial_value => 0,
# );
# p $reducer->{source};
# $reducer->reduce_n(4);
# print "AVG reduce_all = ", $reducer->get_avg;

# my $reducer = Local::Reducer::MaxDiff->new(
#     top => 'received',
#     bottom => 'sended',
#     source => Local::Source::Text->new(text =>"sended:0,received:1000000\nsended:2048,received:10240"),
#     row_class => 'Local::Row::Simple',
#     initial_value => 0,
# );
# p $reducer->{source};
# $reducer->reduce_all;
# print "reduce_all MaxDiff = ", $reducer->reduce_all();

# my $reducer = Local::Reducer::MinMaxAvg->new(
#     field => 'price',
#     source => Local::Source::FileHandler->new(fh => '1.txt'),
#     row_class => Local::Row::JSON,
#     initial_value => undef,
# );
# p $reducer->{source};
# $reducer->reduce_n(1);
# print 'reduce_n(1) Min = ', $reducer->get_min;
# $reducer->reduce_n(3);
# print 'reduce_n(3) Max = ', $reducer->get_max;