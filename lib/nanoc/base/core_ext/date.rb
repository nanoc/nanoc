require 'date'

begin
  d = ::Date.today
  d.freeze
  d.year
  needs_patch = false
rescue => e
  needs_patch = true
end

if needs_patch
 
  class ::Date

    [ :amjd, :jd, :day_fraction, :mjd, :ld, :civil, :ordinal, :commercial, :weeknum0, :weeknum1, :time, :wday, :julian?, :gregorian?, :leap? ].each do |m|
      module_eval <<EOS
        alias_method :__orig_#{m}, :#{m}
        def #{m}
          self.frozen? ? self.dup.#{m} : self.send(:__orig_#{m})
        end
EOS
    end

  end

end
