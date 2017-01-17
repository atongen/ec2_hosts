module Ec2Hosts
  # Updater implements a simple state machine which is used to update
  # content between zero or more blocks of content which start and end
  # with pre-defined "marker" lines.
  class Updater

    module Marker
      BEFORE = 0
      INSIDE = 1
      AFTER = 2
    end

    attr_reader :options

    def initialize(options = {})
      @options = options
    end

    def update(new_hosts)
      old_hosts = File.read(options[:file])

      if old_hosts.include?(start_marker) && old_hosts.include?(end_marker)
        # valid markers exists
        if options[:delete]
          new_content = delete_vpc_hosts(old_hosts)
        else
          new_content = gen_new_hosts(old_hosts, new_hosts)
        end

        # remove zero or more white space characters at end of file with
        # a single new-line
        new_content.gsub!(/\s+$/, "\n")

        if options[:dry_run]
          puts new_content
        elsif new_content != old_hosts
          # backup old host file
          File.open(options[:backup], 'w') { |f| f << old_hosts }
          # write new content
          File.open(options[:file], 'w') { |f| f << new_content }
        end
      elsif old_hosts.include?(start_marker) || old_hosts.include?(end_marker)
        raise UpdaterError.new("Invalid marker present in existing hosts content")
      else
        # marker doesn't exist
        if options[:delete]
          new_content = old_hosts
        else
          new_content = [old_hosts, start_marker, new_hosts, end_marker].join("\n")
        end
        # remove one or more white space characters at end of file with
        # a single new-line
        new_content.gsub!(/\s+$/, "\n")

        if options[:dry_run]
          puts new_content
        elsif new_content != old_hosts
          # backup old host file
          File.open(options[:backup], 'w') { |f| f << old_hosts }
          # write new content
          File.open(options[:file], 'w') { |f| f << new_content }
        end
      end

      true
    end

    def clear
      old_hosts = File.read(options[:file])
      new_content = old_hosts.dup

      markers = old_hosts.each_line.map do |line|
        regex = "\# (START|END) EC2 HOSTS - (.+) \#"
        if m = line.match(/^#{regex}$/)
          m[2]
        end
      end.compact.uniq

      markers.each do |project|
        new_content = delete_vpc_hosts(new_content)
      end
      new_content.gsub!(/\s+$/, "\n")

      if options[:dry_run]
        puts new_content
      elsif new_content != old_hosts
        # backup old host file
        File.open(options[:file], 'w') { |f| f << old_hosts }
        # write new content
        File.open(options[:file], 'w') { |f| f << new_content }
      end
    end

  private

    def gen_new_hosts(hosts, new_hosts)
      new_content = ''
      marker_state = Marker::BEFORE
      hosts.split("\n").each do |line|
        if line == start_marker
          if marker_state == Marker::BEFORE
            # transition to inside the marker
            new_content << start_marker + "\n"
            marker_state = Marker::INSIDE
            # add new host content
            new_hosts.split("\n").each do |host|
              new_content << host + "\n"
            end
          else
            raise UpdaterError.new("Invalid marker state")
          end
        elsif line == end_marker
          if marker_state == Marker::INSIDE
            # transition to after the marker
            new_content << end_marker + "\n"
            marker_state = Marker::AFTER
          else
            raise UpdaterError.new("Invalid marker state")
          end
        else
          case marker_state
          when Marker::BEFORE, Marker::AFTER
            new_content << line + "\n"
          when Marker::INSIDE
            # skip everything between old markers
            next
          end
        end
      end
      new_content
    end

    def delete_vpc_hosts(hosts)
      new_content = ''
      marker_state = Marker::BEFORE
      hosts.split("\n").each do |line|
        if line == start_marker
          if marker_state == Marker::BEFORE
            marker_state = Marker::INSIDE
            # don't add any content, we're deleting this block
          else
            raise UpdaterError.new("Invalid marker state")
          end
        elsif line == end_marker
          if marker_state == Marker::INSIDE
            marker_state = Marker::AFTER
          else
            raise UpdaterError.new("Invalid marker state")
          end
        else
          case marker_state
          when Marker::BEFORE, Marker::AFTER
            new_content << line + "\n"
          when Marker::INSIDE
            # skip everything between old markers
            next
          end
        end
      end
      new_content
    end

    def start_marker
      @start_marker ||= begin
        "# START EC2 HOSTS - #{options[:vpc]} #"
      end
    end

    def end_marker
      @end_marker ||= begin
        "# END EC2 HOSTS - #{options[:vpc]} #"
      end
    end

  end
end
