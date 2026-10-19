/* Exercise host-window resizing and real pointer input, rather than changing
 * resolution with xrandr (which itself refreshes Xephyr's stale RandR state). */
#include <X11/Xlib.h>
#include <X11/Xatom.h>
#include <assert.h>
#include <stdio.h>
#include <unistd.h>

/* Only the Xtst runtime library is needed in the development container. */
extern int XTestFakeMotionEvent(Display *, int, int, int, unsigned long);
extern int XTestFakeButtonEvent(Display *, unsigned int, Bool, unsigned long);

static void motion(Display *host, int x, int y)
{
	XTestFakeMotionEvent(host, 0, x, y, 0);
	XFlush(host);
	usleep(80000);
}

static void button(Display *host, Bool pressed)
{
	XTestFakeButtonEvent(host, 1, pressed, 0);
	XFlush(host);
	usleep(80000);
}

static void check_workarea(Display *display, Window root, int width, int height)
{
	Atom type;
	int format;
	unsigned long count, remaining;
	unsigned char *value = NULL;

	assert(XGetWindowProperty(display, root,
	       XInternAtom(display, "_NET_WORKAREA", False), 0, 4, False,
	       XA_CARDINAL, &type, &format, &count, &remaining, &value) == Success);
	assert(type == XA_CARDINAL && format == 32 && count == 4);
	printf("workarea: %lux%lu\n", ((unsigned long *)value)[2], ((unsigned long *)value)[3]);
	assert(((unsigned long *)value)[2] == (unsigned long)width);
	assert(((unsigned long *)value)[3] == (unsigned long)height);
	XFree(value);
}

/* Check the visible Clip and Dock separately: overlapping them at the left
 * used to hide the Clip when the shipped negative Dock offset was restored. */
static void check_edge_tiles(Display *display, Window root, int width)
{
	Window returned_root, parent, *children;
	unsigned int count;
	int left = 0, right = 0, launcher = 0;

	assert(XQueryTree(display, root, &returned_root, &parent, &children, &count));
	for (unsigned int i = 0; i < count; i++) {
		XWindowAttributes attributes;
		if (!XGetWindowAttributes(display, children[i], &attributes) ||
		    attributes.map_state != IsViewable ||
		    attributes.width != 64 || attributes.height != 64)
			continue;
		if (attributes.x == 0 && attributes.y == 0)
			left++;
		if (attributes.x == width - 64 && attributes.y == 0)
			right++;
		if (attributes.x == width - 64 && attributes.y == 64)
			launcher++;
	}
	XFree(children);
	printf("edge tiles at width %d: Clip=%d Dock=%d launcher=%d\n", width, left, right, launcher);
	assert(left && right && launcher);
}

int main(int argc, char **argv)
{
	Display *display, *host;
	Window root, host_root, returned_root, parent, child, xephyr, window, *children;
	unsigned int count;
	int x, y, found_menu = 0;

	assert(argc == 3);
	setbuf(stdout, NULL);
	host = XOpenDisplay(argv[1]);
	display = XOpenDisplay(argv[2]);
	assert(display && host);
	root = DefaultRootWindow(display);
	host_root = DefaultRootWindow(host);
	assert(XQueryTree(host, host_root, &returned_root, &parent, &children, &count));
	assert(count == 1); /* A private Xvfb contains only Xephyr. */
	xephyr = children[0];
	XFree(children);

	window = XCreateSimpleWindow(display, root, 50, 100, 250, 150, 0, 0, 0);
	XStoreName(display, window, "Resize interaction regression");
	XMapWindow(display, window);
	XFlush(display);
	sleep(1);
	check_edge_tiles(display, root, 800);

	for (int pass = 0; pass < 4; pass++) {
		for (int step = 0; step < 40; step++) {
			XResizeWindow(host, xephyr, 1080 + step * 16, 800 + step * 12);
			XFlush(host);
			usleep(10000);
		}
		XSync(host, False);
		usleep(300000);
	}
	sleep(1);
	check_workarea(display, root, 1704, 1268);
	check_edge_tiles(display, root, 1704);
	XResizeWindow(host, xephyr, 640, 480);
	XSync(host, False);
	sleep(1);
	check_workarea(display, root, 640, 480);
	check_edge_tiles(display, root, 640);
	XResizeWindow(host, xephyr, 1704, 1268);
	XSync(host, False);
	sleep(1);
	check_edge_tiles(display, root, 1704);

	/* Drag the titlebar with input delivered through the outer Xephyr window. */
	XTranslateCoordinates(display, window, root, 0, 0, &x, &y, &child);
	motion(host, x + 60, y - 12);
	button(host, True);
	motion(host, x + 70, y - 12);
	motion(host, 1450, 900);
	button(host, False);
	sleep(1);
	XTranslateCoordinates(display, window, root, 0, 0, &x, &y, &child);
	printf("dragged client: %d,%d\n", x, y);
	assert(x > 1250 && y > 800);

	/* Move the client aside before opening the root menu in the new area. */
	XMoveWindow(display, window, 30, 80);
	XFlush(display);
	sleep(1);
	assert(XQueryTree(display, root, &returned_root, &parent, &children, &count));
	int mapped[count];
	for (unsigned int i = 0; i < count; i++) {
		XWindowAttributes attributes;
		assert(XGetWindowAttributes(display, children[i], &attributes));
		mapped[i] = attributes.map_state == IsViewable;
	}
	motion(host, 1450, 950);
	XTestFakeButtonEvent(host, 3, True, 0);
	XTestFakeButtonEvent(host, 3, False, 100);
	XFlush(host);
	sleep(1);
	for (unsigned int i = 0; i < count; i++) {
		XWindowAttributes attributes;
		if (XGetWindowAttributes(display, children[i], &attributes) &&
		    !mapped[i] && attributes.map_state == IsViewable &&
		    attributes.width > 80 && attributes.height > 50) {
			printf("opened menu: %d,%d\n", attributes.x, attributes.y);
			assert(attributes.x > 1200 && attributes.y > 800);
			found_menu = 1;
		}
	}
	assert(found_menu);
	XFree(children);
	XDestroyWindow(display, window);
	XCloseDisplay(display);
	XCloseDisplay(host);
	return 0;
}
