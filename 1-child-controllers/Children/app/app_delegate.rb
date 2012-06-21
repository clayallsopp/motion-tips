class AppDelegate
	def application(application, didFinishLaunchingWithOptions:launchOptions)
    rootController = UIViewController.alloc.init
    rootController.view.backgroundColor = UIColor.blueColor
    rootController.title = "Root"

    push = UIButton.buttonWithType(UIButtonTypeRoundedRect)
    push.setTitle("Push", forState: UIControlStateNormal)
    push.sizeToFit
    push.addTarget(self, action: 'push', forControlEvents: UIControlEventTouchUpInside)
    rootController.view.addSubview(push)

	 	@navigation_controller = VerticalNavigationController.alloc.initWithRootViewController(rootController)

	 	@window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds)
	 	@window.rootViewController = @navigation_controller
    @window.makeKeyAndVisible
	  
	  true
	end

  def push
    new_controller = UIViewController.alloc.init
    new_controller.view.backgroundColor = UIColor.colorWithRed(rand, green:rand, blue:rand, alpha: 1)
    new_controller.title = (0...8).map{65.+(rand(25)).chr}.join

    push = UIButton.buttonWithType(UIButtonTypeRoundedRect)
    push.setTitle("Push", forState: UIControlStateNormal)
    push.sizeToFit
    push.addTarget(self, action: 'push', forControlEvents: UIControlEventTouchUpInside)
    new_controller.view.addSubview(push)

    pop = UIButton.buttonWithType(UIButtonTypeRoundedRect)
    pop.setTitle("Pop", forState: UIControlStateNormal)
    pop.sizeToFit
    pop.addTarget(@navigation_controller, action: 'pop', forControlEvents: UIControlEventTouchUpInside)
    pop.setFrame(CGRectMake(0, push.frame.size.height, pop.frame.size.width, pop.frame.size.height))
    new_controller.view.addSubview(pop)

    @navigation_controller.push(new_controller)
  end
end