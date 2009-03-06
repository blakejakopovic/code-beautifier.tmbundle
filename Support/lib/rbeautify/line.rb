module RBeautify

  class Line

    # tab character and size
    @@tab_char = " "
    @@tab_size = 2

    # ignore regexp tests
    #
    # TODO: Replace with proper inline blockmatchers so that blocks are matched
    # even if they begin and end on the same line
    @@indent_irrelevant_content_matchers = [
      [/\\"|\\'/, false],     # Remove escaped quotes
      [/'.*?'/, true],
      [/".*?"/, true],        # Ignore contents of quoted strings
      [/\/.*?\//, true],      # Ignore contents of regexes
      [/#[^\"]+$/, false],    # Remove end-of-line comments
      [/\{[^\{]*?\}/, true],  # Ignore contents of matched curly braces
      [/\[[^\[]*?\]/, true],  # Ignore contents of matched square braces
      [/\([^\(]*?\)/, true],  # Ignore contents of matched round braces
      [/\`.*?\`/, true]       # Ignore contents of matched backticks
    ]

    attr_accessor :content, :original_stack

    def initialize(content, original_stack = [])
      self.content = content
      self.original_stack = original_stack
    end

    def format
      if @formatted.nil?
        if format?
          if stripped.length == 0
            @formatted = ""
          else
            @formatted = tab_string + stripped
          end
        else
          @formatted = content
        end
      end

      @formatted
    end

    def stack
      if @stack.nil?
        @stack = original_stack.dup

        if ended_block
          @stack.pop
        end

        if format?
          BlockMatcher::MATCHERS.each do |matcher|
            if block = matcher.block(indent_relevant_content, @stack.last)
              @stack.push(block)
            end
          end
        end
      end

      @stack
    end

    private

    def ended_block
      @ended_block ||= (!indent_relevant_content.empty? && original_stack.last && original_stack.last.end?(indent_relevant_content)) ? original_stack.last : nil
    end

    def format?
      original_stack.last.nil? || original_stack.last.format?
    end

    def tabs
      if ended_block && !ended_block.indent_end_line?
        original_stack.size - 1
      else
        original_stack.size
      end
    end

    def tab_string
      @@tab_char * @@tab_size * tabs
    end

    def stripped
      @stripped = content.strip
    end

    # Remove content from the string that does not have any relevance to
    # indentation.
    #
    # Doing this enables the block matcher regexes to be much simpler
    def indent_relevant_content
      unless @indent_relevant_content.nil?
        return @indent_relevant_content
      end

      @indent_relevant_content = stripped.dup
      @@indent_irrelevant_content_matchers.each do |re|
        # Replace the content with a dummy placeholder or nothing at all
        @indent_relevant_content.gsub!(re.first, re.last ? ' | ' : '')
      end
      @indent_relevant_content.strip

    end

  end

end