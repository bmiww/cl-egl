;;;; package.lisp

(defpackage :egl
  (:use :common-lisp :cffi)
  (:export
   get-error
   get-display
   initialize
   bind-api
   choose-config
   create-context
   get-current-context
   create-window-surface
   make-current
   swap-buffers
   destroy-surface
   destroy-context
   terminate
   get-proc-address
   bind-wl-display
   unbind-wl-display
   query-wayland-buffer
   image-target-texture-2DOES
   eglintor
   EGLenum
   load-egl-extensions

   create-image destroy-image
   create-image-khr destroy-image-khr))
