class VerticalNavigationBar < UIView
	attr_accessor :title

	def initWithFrame(frame)
		super
		self.backgroundColor = UIColor.redColor
		@title_view = UILabel.alloc.initWithFrame(CGRectZero)
		self.addSubview(@title_view)
		self
	end

	def title
		@title ||= ""
	end

	def title=(title)
		@title = title
		@title_view.setText(@title)
		@title_view.sizeToFit
		@title
	end
end