require 'date'

module Maya
    def self.nihonjikan()
        return DateTime.now.new_offset('+09:00').strftime("%H:%M")
    end
end