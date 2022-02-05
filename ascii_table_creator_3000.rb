require 'readline'
require 'rainbow/refinement'
require 'terminal-table'

using Rainbow


class String
  def integer?
    to_i.to_s == self
  end
end


class TableHandler

  attr_reader :table
  attr_reader :title_enabled
  attr_reader :title
  attr_reader :headings_enabled
  attr_reader :headings
  attr_reader :rows
  attr_reader :style

  def initialize
    @title_enabled = false
    @title = ""
    @headings_enabled = false
    @headings = []
    @rows = []
    @style = {
      :border => :ascii
    }
    update_table(false)
  end

  def update_table(print = true)
    @table = Terminal::Table.new(
      :title => @title_enabled ? @title : nil,
      :headings => @headings_enabled ? @headings : [],
      :rows => @rows,
      :style => @style
    )
    if print
      puts @table
    end
  end

  def clear_table
    @rows = []
    @table = Terminal::Table.new :rows => @rows
  end

  def add(index = @rows.length, row)
    @rows.insert(index, row)
  end

  def remove(index = @rows.length - 1)
    @rows.delete_at(index)
  end

  def set_title(title)
    if not title.empty?
      @title = title
      @title_enabled = true
    else
      @title_enabled = false
    end
  end

  def set_headings(headings)
    if not headings.empty?
      @headings = headings
      @headings_enabled = true
    else
      @headings_enabled = false
    end
  end

  def set_style_key(key, value)
    style[key] = value
  end
end


class InteractiveSession

  def initialize
    @th = TableHandler.new
    @prompt = (" >>> ").bg(:blue) + " " # the prompt shown in the interactive session
    @commands = { # list of commands and their corresponding methods
      "help" => method(:cmd_help),
      "exit" => method(:cmd_exit),
      "table" => method(:cmd_table),
      "clear" => method(:cmd_clear),
      "save" => method(:cmd_save),
      "add" => method(:cmd_add),
      "remove" => method(:cmd_remove),
      "set_title" => method(:cmd_set_title),
      "set_headings" => method(:cmd_set_headings),
      "set_border_style" => method(:cmd_set_border_style),
      "set_all_separators" => method(:cmd_set_all_separators),
    }
    @commands_help = { # list of commands and their corresponding help messages
      "help" => ["", "Displays this help message"],
      "exit" => ["", "Exits the program"],
      "table" => ["", "Displays the current table"],
      "clear" => ["", "Clears the table"],
      "save" => ["<filename>", "Saves the current table to a file"],
      "add" => ["<index> <row>", "Adds a row to the table at the specified index. If no index is specified, the row is added at the end"],
      "remove" => ["<index>", "Removes the row at the specified index from the table. If no index is specified, the last row is removed"],
      "set_title" => ["<title>", "Sets the title of the table. If no title is specified, the title is disabled"],
      "set_headings" => ["<headings>", "Sets the headings of the table. If no headings are specified, the headings are disabled"],
      "set_border_style" => ["<style>", "Sets the border style of the table. The style can be one of the following:  ascii, markdown, unicode, unicode_round, unicode_thick_edge"],
      "set_all_separators" => ["<true/false>", "Enables/disables separator for all table elements"],
    }
  end

  def start_session
    puts "Welcome to the interactive ".green + "ascii_table_creator_3000!".bright.blue
    puts "Type ".green + "help".yellow + " for a list of commands.".green
    puts "Type ".green + "exit".red + " or press ".green + "CTRL+C".red + " to quit.".green

    while input = Readline.readline(@prompt, true)

      input_split = input.split(" ")
      command = input_split[0]
      # args passed to the command methods is just the substring after the command in the input
      # each command does it's own arg parsing
      args = input.sub(command, "")

      if @commands.key?(command)
        @commands[command].call(args)
      else
        puts "Unknown command: #{command}".red
        puts "Type ".green + "help".yellow + " for a list of commands.".green
      end
    end
  end

  def cmd_help(args)
    args = args.split(" ")
    if args.length == 0 # if no args, display all commands
      puts "ascii_table_creator_3000 ".bright.blue + "is a simple interactive Ruby program that helps you create ascii tables right on your terminal!".green
      puts "Available commands:".green
      @commands.each do |key, value|
        puts "  #{key}".bright.yellow + " #{@commands_help[key][0]}".blue.bright.italic + " - #{@commands_help[key][1]}"
      end
    else
      if @commands_help.key?(args[0]) # if the first arg is a command, display its help
        puts "  #{args[0]}".bright.yellow + " #{@commands_help[args[0]][0]}".blue.bright.italic + " - #{@commands_help[args[0]][1]}"
      else  # otherwise, display an error message
        puts "Unknown command: #{args[0]}".red
        puts "Type ".green + "help".yellow + " for a list of commands.".green
      end
    end
  end

  def cmd_exit(args)
    puts "Goodbye!".red
    exit
  end

  def cmd_table(args)
    @th.update_table
  end

  def cmd_clear(args)
    @th.clear_table
  end

  def cmd_save(args)
    args = args.split(" ")
    if args.length == 0 # if no args, ask for filename
      puts "Please specify a filename.".red
    else
      filename = args[0]
      if not filename.include?(".txt") # if filename doesn't have .txt, append it
        filename += ".txt"
      end
      File.open(filename, "w") do |f|
        f.write(@th.table)
        puts "File saved successfully as #{filename}".green
      end
    end
  end

  def cmd_add(args)
    if args.count('"') > 1 # if args has more than two quotes, then parse it accordingly
      new_args = args.scan(/"([^"]+)"/)
      # the scan above outputs an array which each element of it is a separate array
      # rather than a string, the for loop below "converts" each element to a string
      new_args.each_with_index do |arg, index|
        new_args[index] = arg[0]
      end
      # if the first argument is an integer, add it to the new_args array
      # this is because the scan omits anything that isn't wrapped in quotes
      if args.split(" ")[0].integer?
        new_args.insert(0, args.split(" ")[0])
      end
      args = new_args
    else # otherwise just split it into an array by whiespaces
      args = args.split(" ")
    end

    if args[0].integer? # if the first argument is an integer, add a row at that index
      if args[0].to_i > @th.rows.length  # if the index is greater than the number of rows, add the row at the end
        @th.add(@th.rows.length, args[1..-1])
      else
        @th.add(args[0].to_i, args[1..-1])
      end
    else
      @th.add(args[0..-1]) # otherwise, add a row at the end
    end
    @th.update_table
  end

  def cmd_remove(args)
    args = args.split(" ")
    if args.length == 0  # if there is no index arg, remove last row
      @th.remove
    elsif args[0].integer?
      if args[0].to_i > @th.rows.length # if index is out of bounds, remove last row
        @th.remove
      else
        @th.remove(args[0].to_i) # otherwise remove row at index
      end
    end
    @th.update_table
  end

  def cmd_set_title(args)
    if args.length == 0
      @th.set_title("")
      @th.update_table
    else
      @th.set_title(args)
      @th.update_table
    end
  end

  def cmd_set_headings(args)
    if args.count('"') > 1 # same arg parsing as the add command
      new_args = args.scan(/"([^"]+)"/)
      new_args.each_with_index do |arg, index|
        new_args[index] = arg[0]
      end
      if args.split(" ")[0].integer?
        new_args.insert(0, args.split(" ")[0])
      end
      args = new_args
    else
      args = args.split(" ")
    end

    if args.length == 0
      @th.set_headings("")
      @th.update_table
    else
      @th.set_headings(args[0..-1])
      @th.update_table
    end
  end

  def cmd_set_border_style(args)
    args = args.split(" ")

    case args[0]
    when "ascii"
      @th.set_style_key(:border, :ascii)
      @th.update_table
    when "markdown"
      @th.set_style_key(:border, :markdown)
      @th.update_table
    when "unicode"
      @th.set_style_key(:border, :unicode)
      @th.update_table
    when "unicode_round"
      @th.set_style_key(:border, :unicode_round)
      @th.update_table
    when "unicode_thick_edge"
      @th.set_style_key(:border, :unicode_thick_edge)
      @th.update_table
    else
      puts "The border_style value can only be one of the following:".red
      puts "  ascii".yellow
      puts "  markdown".yellow
      puts "  unicode".yellow
      puts "  unicode_round".yellow
      puts "  unicode_thick_edge".yellow
    end
  end

  def cmd_set_all_separators(args)
    args = args.split(" ")

    case args[0]
    when "true"
      @th.set_style_key(:all_separators, true)
      @th.update_table
    when "false"
      @th.set_style_key(:all_separators, false)
      @th.update_table
    else
      puts "The all_separators value can only be true or false".red
    end
  end
end

session = InteractiveSession.new
session.start_session
