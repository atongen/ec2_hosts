# ec2_hosts

Update your hosts file based on ec2 compute instances.

This is handy when used in conjunction with something like [sshuttle](https://github.com/sshuttle/sshuttle),
allowing you to have a "poor man's vpn".

## Installation

```shell
$ gem install ec2_hosts
```

## Requirements

## Usage

## Example

Update your hosts file using ec2_hosts:

```shell
$ sudo ec2_hosts -p my-cool-project --public bastion

```
Start sshuttle session:

```shell
$ sshuttle --remote=bastion01 --daemon --pidfile=/tmp/sshuttle.pid 192.168.1.0/24
```

Now your hosts file will contain entries for all compute instances in the project,
and you can ssh directly to them from your local machine.

Hosts matching the pattern passed in with the `--public` flag will have their public
IP address added to your host file instead of the their private internal IP address.

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/atongen/ec2_hosts](https://github.com/atongen/ec2_hosts).
