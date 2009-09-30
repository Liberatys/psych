module Psych
  module Visitors
    class YASTBuilder < Psych::Visitors::Visitor
      attr_reader :tree

      def initialize options = {}
        super()
        @tree = Nodes::Stream.new
        @tree.children << Nodes::Document.new
        @stack = @tree.children.dup
      end

      def accept target
        target.class.ancestors.each do |klass|
          method_name = :"visit_#{target.class.name.split('::').join('_')}"
          if respond_to?(method_name)
            return send(method_name, target)
          end
        end
        raise TypeError, "Can't dump #{target.class}"
      end

      def visit_String o
        @stack.last.children << Nodes::Scalar.new(o)
      end

      def visit_Class o
        raise TypeError, "can't dump anonymous class #{o.class}"
      end

      def visit_Hash o
        @stack.push append Nodes::Mapping.new

        o.each do |k,v|
          k.accept self
          v.accept self
        end

        @stack.pop
      end

      def visit_Array o
        @stack.push append Nodes::Sequence.new
        o.each { |c| c.accept self }
        @stack.pop
      end

      private
      def append o
        @stack.last.children << o
        o
      end
    end
  end
end