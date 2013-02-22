require 'dentaku/token'
require 'dentaku/token_matcher'

module Dentaku
  class Rules
    def self.each
      @rules ||= [
        [ p(:if),         :if             ],
        [ p(:round_one),  :round          ],
        [ p(:round_two),  :round          ],
        [ p(:roundup),    :round_int      ],
        [ p(:rounddown),  :round_int      ],
        [ p(:not),        :not            ],

        [ p(:group),      :evaluate_group ],
        [ p(:math_pow),   :apply          ],
        [ p(:math_mul),   :apply          ],
        [ p(:math_add),   :apply          ],
        [ p(:range_asc),  :expand_range   ],
        [ p(:range_desc), :expand_range   ],
        [ p(:num_comp),   :apply          ],
        [ p(:str_comp),   :apply          ],
        [ p(:combine),    :apply          ]
      ]

      @rules.each { |r| yield r }
    end

    def self.t(name)
      @matchers ||= [
        [:numeric,        [:numeric]],
        [:string,         [:string]],
        [:addsub,         [:operator, [:add, :subtract]]],
        [:muldiv,         [:operator, [:multiply, :divide]]],
        [:pow,            [:operator, :pow]],
        [:comparator,     [:comparator]],
        [:comp_gt,        [:comparator, [:gt, :ge]]],
        [:comp_lt,        [:comparator, [:lt, :le]]],
        [:open,           [:grouping, :open]],
        [:close,          [:grouping, :close]],
        [:comma,          [:grouping, :comma]],
        [:logical,        [:logical]],
        [:combinator,     [:combinator]],
        [:if,             [:function, :if]],
        [:round,          [:function, :round]],
        [:roundup,        [:function, :roundup]],
        [:rounddown,      [:function, :rounddown]],
        [:not,            [:function, :not]],
      ].each_with_object({}) do |(key, args), matchers|
        matchers[key] = TokenMatcher.new(*args)
      end

      @matchers[:non_group]      ||= TokenMatcher.new(:grouping).invert
      @matchers[:non_group_star] ||= TokenMatcher.new(:grouping).invert.star

      @matchers[name]
    end

    def self.p(name)
      @patterns ||= {
        group:      pattern(:open,    :non_group_star, :close),
        math_add:   pattern(:numeric, :addsub,         :numeric),
        math_mul:   pattern(:numeric, :muldiv,         :numeric),
        math_pow:   pattern(:numeric, :pow,            :numeric),
        range_asc:  pattern(:numeric, :comp_lt,        :numeric,  :comp_lt, :numeric),
        range_desc: pattern(:numeric, :comp_gt,        :numeric,  :comp_gt, :numeric),
        num_comp:   pattern(:numeric, :comparator,     :numeric),
        str_comp:   pattern(:string,  :comparator,     :string),
        combine:    pattern(:logical, :combinator,     :logical),

        if:         func_pattern(:if,        :non_group,      :comma, :non_group, :comma, :non_group),
        round_one:  func_pattern(:round,     :non_group_star),
        round_two:  func_pattern(:round,     :non_group_star, :comma, :numeric),
        roundup:    func_pattern(:roundup,   :non_group_star),
        rounddown:  func_pattern(:rounddown, :non_group_star),
        not:        func_pattern(:not,       :non_group_star)
      }

      @patterns[name]
    end

    def self.pattern(*symbols)
      symbols.map { |s| t(s) }
    end

    def self.func_pattern(func, *tokens)
      pattern(func, :open, *tokens, :close)
    end
  end
end