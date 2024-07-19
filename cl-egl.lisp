
(in-package :egl)

(define-foreign-library libegl
  (:unix (:or "libEGL.so.1"))
  (t (:default "libEGL")))

(use-foreign-library libegl)

(defctype EGLBoolean :uint)
(defctype EGLDisplay :pointer)
(defctype EGLConfig :pointer)
(defctype EGLSurface :pointer)
(defctype EGLContext :pointer)
(defctype EGLint :int32)

(defcenum (eglenum EGLint)
  (:pbuffer-bit #x0001)
  (:window-bit #x0004)
  (:surface-type #x3033)
  (:alpha-size #x3021)
  (:blue-size #x3022)
  (:green-size #x3023)
  (:red-size #x3024)
  (:depth-size #x3025)
  (:renderable-type #x3040)
  (:opengl-bit #x0008)
  (:opengl-es-bit #x0001)
  (:opengl-es3-bit #x00000040)
  (:opengl-es-api #x30A0)
  (:opengl-api #x30A2)
  (:context-major-version #x3098)
  (:context-minor-version #x30FB)
  (:conformant #x3042)
  (:width #x3057)
  (:height #x3056)
  (:color-buffer-type #x303F)
  (:rgb-buffer #x308E)
  (:egl-platform-gbm-khr #x31D7)
  (:linux-drm-fourcc-ext #x3271)

  (:dma-buf-plane0-fd-ext #x3272)
  (:dma-buf-plane0-offset-ext #x3273)
  (:dma-buf-plane0-pitch-ext #x3274)


  ;; ERROR CODES
  (:success #x3000)
  (:not-initialized #x3001)
  (:bad-access #x3002)
  (:bad-alloc #x3003)
  (:bad-attribute #x3004)
  (:bad-config #x3005)
  (:bad-context #x3006)
  (:bad-current-surface #x3007)
  (:bad-display #x3008)
  (:bad-match #x3009)
  (:bad-native-pixmap #x300A)
  (:bad-native-window #x300B)
  (:bad-parameter #x300C)
  (:bad-surface #x300D)
  (:context-lost #x300E)

  (:none #x3038))

(defvar LINUX_DMA_BUF_EXT #x3270)

(defun eglintor (&rest args)
  (apply 'logior (mapcar (lambda (x) (foreign-enum-value 'eglenum x)) args)))

(defcfun ("eglGetError" get-error-internal) EGLint)
(defun get-error () (foreign-enum-keyword 'eglenum (get-error-internal)))

(defcfun ("eglGetDisplay" get-display) EGLDisplay
  (display-id :pointer))

(defcfun "eglInitialize" EGLBoolean
  (display EGLDisplay)
  (major :pointer)
  (minor :pointer))

(defun initialize (display)
  (with-foreign-objects
      ((major 'EGLint 1)
       (minor 'EGLint 1))
    (when (= (eglInitialize display major minor) 0)
      (terminate display)
      (error "Failed to initialize EGL with code ~d" (get-error)))
    (format t "~A~%" (get-error))
    (values (mem-aref major 'EGLint)
	    (mem-aref minor 'EGLint))))

(defcfun "eglChooseConfig" EGLBoolean
  (display EGLDisplay)
  (attrib-list (:pointer EGLint))
  (configs (:pointer EGLConfig))
  (config-size EGLint)
  (num-config (:pointer EGLint)))

(defun choose-config (display &rest config-attribs)
  (let ((config-size 0))
    (with-foreign-objects
	((requested-attribs 'EGLint (length config-attribs))
	 (available-configs '(:pointer EGLConfig) 1)
	 (num-configs 'EGLint 1))
      (loop :for i :from 0 :to (- (length config-attribs) 1)
	    :do (setf (mem-aref requested-attribs 'EGLint i)
		      (if (keywordp (nth i config-attribs))
			  (foreign-enum-value 'eglenum (nth i config-attribs))
			  (nth i config-attribs))))
      (eglchooseconfig display requested-attribs (cffi:null-pointer) 0 num-configs)
      (setf config-size (cffi:mem-ref num-configs 'EGLint))
      (eglchooseconfig display requested-attribs available-configs config-size num-configs)
      (loop :for i :from 0 :to (- (mem-aref num-configs 'EGLint) 1)
	    :collecting (mem-aref available-configs :pointer i)))))

(defcfun ("eglGetCurrentContext" get-current-context) EGLContext)

(defcfun "eglCreateContext" EGLContext
  (display EGLDisplay)
  (config EGLConfig)
  (share-context EGLContext)
  (attrib-list (:pointer EGLint)))

(defun create-context (display config share-context &rest attribs)
  (with-foreign-objects
      ((requested-attribs 'EGLint (length attribs)))
    (loop :for i :from 0 :to (- (length attribs) 1)
       :do (setf (mem-aref requested-attribs 'EGLint i)
		 (if (keywordp (nth i attribs))
		     (foreign-enum-value 'eglenum (nth i attribs))
		     (nth i attribs))))
    (eglcreatecontext display config share-context requested-attribs)))

(defcfun ("eglCreateWindowSurface" create-window-surface) EGLSurface
  (display EGLDisplay)
  (config EGLConfig)
  (win :pointer)
  (attrib-list (:pointer EGLint)))

(defcfun ("eglTerminate" terminate) EGLBoolean
  (display EGLDisplay))

(defcfun "eglBindAPI" EGLBoolean
  (api :uint))

(defun bind-api (api)
  (eglbindapi (foreign-enum-value 'eglenum api)))

(defcfun ("eglMakeCurrent" make-current) EGLBoolean
  (display EGLDisplay)
  (draw EGLSurface)
  (read EGLSurface)
  (context EGLContext))

(defcfun ("eglSwapBuffers" swap-buffers) EGLBoolean
  (display EGLDisplay)
  (surface EGLSurface))

(defcfun ("eglDestroySurface" destroy-surface) EGLBoolean
  (display EGLDisplay)
  (surface EGLSurface))

(defcfun ("eglDestroyContext" destroy-context) EGLBoolean
  (display EGLDisplay)
  (context EGLContext))

(defcfun ("eglCreateImage" create-image) :pointer
  (display EGLDisplay)
  (context EGLContext)
  (target EGLint)
  (buffer :pointer)
  (attrib-list (:pointer EGLint)))

(defcfun ("eglDestroyImage" destroy-image) EGLBoolean
  (display EGLDisplay)
  (image :pointer))

(defcfun ("eglGetProcAddress" get-proc-address) :pointer
  (name :string))

(defvar *query-wayland-display* nil)
(defvar *bind-wayland-display* nil)
(defvar *unbind-wayland-display* nil)
(defvar *image-target-texture-2DOES* nil)
(defvar *create-image-khr* nil)
(defvar *destroy-image-khr* nil)

(defmacro setfnot (place value)
  `(unless ,place (setf ,place ,value)))

(defun load-egl-extensions ()
  (setfnot *bind-wayland-display* (get-proc-address "eglBindWaylandDisplayWL"))
  (setfnot *unbind-wayland-display* (get-proc-address "eglUnbindWaylandDisplayWL"))
  (setfnot *query-wayland-display* (get-proc-address "eglQueryWaylandBufferWL"))
  (setfnot *image-target-texture-2DOES* (get-proc-address "glEGLImageTargetTexture2DOES"))
  (setfnot *create-image-khr* (get-proc-address "eglCreateImageKHR"))
  (setfnot *destroy-image-khr* (get-proc-address "eglDestroyImageKHR")))

(defun bind-wl-display (egl-display wl-display)
  (foreign-funcall-pointer *bind-wayland-display* ()
			   :pointer egl-display
			   :pointer wl-display
			   :void))

(defun unbind-wl-display (egl-display wl-display)
  (foreign-funcall-pointer *bind-wayland-display* ()
			   :pointer egl-display
			   :pointer wl-display
			   :void))

(defun query-wayland-buffer (egl-display buffer attribute value)
  (foreign-funcall-pointer *query-wayland-display* ()
			   :pointer egl-display
			   :pointer buffer
			   EGLint attribute
			   :pointer value
			   EGLBoolean))

(defun image-target-texture-2DOES (attribute egl-image)
  (foreign-funcall-pointer *image-target-texture-2DOES* ()
			   EGLint attribute
			   :pointer egl-image
			   :void))

(defun create-image-khr (display context target buffer &rest attribs)
  (with-foreign-objects
      ((requested-attribs 'EGLint (length attribs)))
    (loop :for i :from 0 :to (- (length attribs) 1)
	  :do (setf (mem-aref requested-attribs 'EGLint i)
		    (if (keywordp (nth i attribs))
			(foreign-enum-value 'eglenum (nth i attribs))
			(nth i attribs))))
    (foreign-funcall-pointer *create-image-khr* ()
			     :pointer display
			     :pointer context
			     EGLint target
			     :pointer buffer
			     :pointer requested-attribs
			     :pointer)))

(defun destroy-image-khr (display image)
  (foreign-funcall-pointer *destroy-image-khr* ()
			   :pointer display
			   :pointer image
			   :bool))
