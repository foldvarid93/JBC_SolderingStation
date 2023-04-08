cam = webcam;
cam.Resolution = '1280x720';

h = preview(cam);

h.Parent.Parent.Parent.WindowStyle = 'docked';