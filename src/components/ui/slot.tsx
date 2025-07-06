import * as React from "react"

export interface SlotProps extends React.HTMLAttributes<HTMLElement> {
  asChild?: boolean
}

export const Slot = React.forwardRef<HTMLElement, SlotProps>(
  ({ asChild, ...props }, ref) => {
    if (asChild) {
      return React.cloneElement(
        React.Children.only(props.children as React.ReactElement),
        {
          ...props,
          ref,
        }
      )
    }

    return <span {...props} ref={ref} />
  }
)

Slot.displayName = "Slot"