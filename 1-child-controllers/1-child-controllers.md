# Container Controllers

Historically, iOS developers have been limited to just two batteries-included ways of organizing their apps: `UINavigationController`s and `UITabBarController`s. These are `UIViewController`s, but are unique in that they organize other `UIViewController`s as part of their content. Prior to iOS5, there was no formal way of doing the same in a custom manner; you could either manage your own view controller relationships or use one mega-controller with a complex view hierarchy. But what about today, *after* iOS5?

Now we have a concise set of functions in `UIViewController` to add or remove "child" view controllers to a "parent" view controller.

Let's say we want to implement a vertical `UINavigationController`, where pushing a new view controller is transitioned by a vertical slide (instead of the horizontal default).

First we define a `UIViewController` subclass as the container controller; lets call it `VerticalNavigationController`. 

```ruby
class VerticalNavigationController < UIViewController
  def loadView
    self.view = UIView.alloc.initWithFrame(UIScreen.mainScreen.applicationFrame)
  end
end
```

Pretty straightfoward: we created a view sized to fits the screen. You can add whatever "chrome" (navigation bar, tabs, etc) at this point.

Time to start working on how to get our "children" controllers in there. We need an exposed API to do this, so let's do something similar to how `UINavigationController` works. It's usually nice to design systems by writing public methods like these before then writing the internal components:

```ruby
class VerticalNavigationController < UIViewController
  ...
  def push(to_vc, animated = false)
  end

  def pop(animated = false)
  end
  ...
end
```

We know that these two methods should:

1. Add/remove the view controller to some kind of internal stack.
2. Add/remove the view controller as a child VC via UIKit's methods.
3. Add/remove the view controller's view to our container's view hierarchy.
4. Animate the addition/removal of the view controller's view, if applicable.

Let's hammer those out, shall we?

First, the stack. Ruby has some nice methods for treating `Array`s as stacks, so we'll just build ontop of those, using our container's `#push`/`#pop` as a thin proxy for the real `stack`. 

```ruby
class VerticalNavigationController < UIViewController
  ...

  def stack
    @stack ||= []
  end

  def push(to_vc, animated = false)
    from_vc = self.stack[-1] # could be nil
    self.stack.push(to_vc)
  end

  def pop(animated = false)
    # If we have 0 or 1 view controllers, don't pop.
    return if self.stack.count <= 1

    from_vc = self.stack.pop
    to_vc = self.stack[-1]
  end
  ...
end
```

We do some nice checks in `#pop` to make sure we don't pop to an empty stack. I established some semantics to make our lives easier: the controller we're going to display will be `to_vc`, and the one we're hiding is `from_vc`, regardless whether we're pushing or popping.

Next on our list, we need to add the `UIViewController` methods for adding child controllers (say that five times fast). They are:

*Adding children**
- `to_vc.willMoveToParentViewController(container)`
- `container.addChildViewController(to_vc)`
- `to_vc.didMoveToParentViewController(container)`

**Removing children**
- `from_vc.willMoveToParentViewController(nil)`
- `from_vc.removeFromParentViewController`
- `from_vc.didMoveToParentViewController(nil)`

**Both**
- `container.transitionFromViewController(from_vc, toViewController:to_vc, duration:time, options:Some | Options, animations: lambda { }, completion: lambda {|finished| })`

In practice, `addChildViewController` calls `willMoveToParentViewController(container)` and  `removeFromParentViewController` calls `didMoveToParentViewController(nil)`, so you only need to use four of those in your implementation (this doesn't happen if you override `automaticallyForwardAppearanceAndRotationMethodsToChildViewControllers`, but let's ignore that for now).

`transitionFromViewController` will handle adding/removing subviews from `container`'s `vier`, so that's even less code you need to worry about.

Armed with this new knowledge, let's flesh out our implementation a bit more.

```ruby
class VerticalNavigationController < UIViewController
  ...
  def push(to_vc, animated = false)
    from_vc = self.stack[-1] # could be nil
    self.stack.push(to_vc)

    self.addChildViewController(to_vc)

    to_vc.view.setFrame(self.view.bounds)

    # transitionFromViewController: breaks if from_vc.nil?
    # so need to handle it as a special case.
    if from_vc.nil?
      to_vc.viewWillAppear(false)
      self.view.addSubview(to_vc.view)
      to_vc.viewDidAppear(false)

      to_vc.didMoveToParentViewController(self)
    else
      to_vc.viewWillAppear(animated)

      self.transitionFromViewController(from_vc, 
          toViewController:to_vc,
                  duration:animated ? 0.3 : 0,
                   options:UIViewAnimationOptionTransitionNone,
                animations: lambda {
                              # do some animations
                           },
                completion:lambda {|finished|
                    to_vc.viewDidAppear(animated)

                    to_vc.didMoveToParentViewController(self)
                  })
    end
  end

  def pop(animated = false)
    return if self.stack.count < 2

    from_vc = self.stack.pop
    to_vc = self.stack[-1]

    from_vc.willMoveToParentViewController(nil)
    from_vc.viewWillDisappear(animated)

    self.transitionFromViewController(from_vc, 
              toViewController:to_vc,
                      duration:animated ? 0.3 : 0,
                       options:UIViewAnimationOptionTransitionNone,
                    animations:lambda {
                                  # do some animations
                               },
                    completion:lambda {|finished|
                        from_vc.removeFromParentViewController
                        from_vc.viewDidDisappear(animated)
                      })
  end
  ...
end
```

It seems like a lot of code, but only because the `transitionFromViewController`s are broken into multiple lines. Let's walk through it.

In each function we find what controller we're going to and what controller we're coming from. Then we call `willMoveToParentViewController` on them (we don't do so in `#push` because `addChildViewController` handles that).

Next we handle what happens to their `view`s. Remember to call the `view[Will/Did]Appear` and `view[Will/Did]Disappear` at the appropriate times (before/after adding/removing it as a subview). We call all the `didX` methods when we're done with our animations in `transitionFromViewController`. The only code that does anything differently is `#push`, which will force a manual addition of the new controller's `view` because there is no `from_vc` sometimes.

And that's about all you need! Just plug in your custom animations or chrome and you're good to go.

I've uploaded a more complete example [here](http://google.com). It's fugly, but shows how to do some animations and lock a navigation bar to the container's `view`.

Thanks!
