class VerticalNavigationController < UIViewController
	def initWithRootViewController(to_vc)
		self.init
		self.push(to_vc)
		self
	end

	def loadView
		self.view = UIView.alloc.initWithFrame(UIScreen.mainScreen.applicationFrame)
		self.view.addSubview(self.navigationBar)
	end

	def navigationBar
		@navigationBar ||= VerticalNavigationBar.alloc.initWithFrame(CGRectMake(0, 0, UIScreen.mainScreen.applicationFrame.size.width, 44))
	end

	def stack
    @stack ||= []
  end

  def push(to_vc, animated = true)
		from_vc = self.stack[-1]
  	self.stack.push(to_vc)

    self.addChildViewController(to_vc)

    pre_animate = lambda {
    	self.navigationBar.title = to_vc.title
    }

    post_animate = lambda { |finished|
    	to_vc.didMoveToParentViewController(self)
    	to_vc.viewDidAppear(animated)
    }

    to_vc.view.frame = child_frame
    to_vc.viewWillAppear(animated)

    if !animated or self.stack.count == 1
			self.view.addSubview(to_vc.view)
			self.view.bringSubviewToFront(self.navigationBar)
    	pre_animate.call
    	post_animate.call(true)
    else
    	to_vc.view.frame = offscreen_bottom_frame
    	self.transitionFromViewController(from_vc, 
                toViewController:to_vc,
                        duration: animated ? 0.3 : 0,
                         options:UIViewAnimationOptionTransitionNone,
                      animations: lambda {
                      							pre_animate.call
                      							from_vc.view.frame = offscreen_top_frame
    																to_vc.view.frame = child_frame
     																self.view.bringSubviewToFront(self.navigationBar)
                                 },
                      completion:post_animate)
    end
  end

  def pop(animated = false)
  	return if self.stack.count < 2

    from_vc = self.stack.pop
    to_vc = self.stack[-1]

    from_vc.viewWillDisappear(animated)

		to_vc.view.frame = offscreen_top_frame
		self.transitionFromViewController(from_vc, 
		          toViewController:to_vc,
		                  duration: animated ? 0.3 : 0,
		                   options:UIViewAnimationOptionTransitionNone,
		                animations: lambda {
    															self.navigationBar.title = to_vc.title
		                							from_vc.view.frame = offscreen_bottom_frame
																	to_vc.view.frame = child_frame
																	self.view.bringSubviewToFront(self.navigationBar)
		                           },
		                completion:lambda { |finished|
														    	from_vc.removeFromParentViewController
														    	from_vc.viewDidDisappear(animated)
														    })
  end

  private
	def child_height
		self.view.bounds.size.height - self.navigationBar.bounds.size.height
	end

	def child_width
		self.view.bounds.size.width
	end

	def child_frame
		CGRectMake(0, self.navigationBar.bounds.size.height, child_width, child_height)
	end

	def offscreen_top_frame
		CGRectMake(0, self.navigationBar.bounds.size.height - child_height, child_width, child_height)
	end

	def offscreen_bottom_frame
		CGRectMake(0, self.view.bounds.size.height, child_width, child_height)
	end
end