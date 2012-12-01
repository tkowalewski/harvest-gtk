
// MIT License
// ===========

// Copyright (c) 2012 Tomasz Kowalewski <me@tkowalewski.pl>

// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
// THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.

using Gtk;
using GLib;
using Soup;
using Gee;
using Xml;

namespace Harvest {

	public class Project : Object {
		private ArrayList<Task?> _tasks;
		public ArrayList<Task?> tasks {
			get { return _tasks; }
			set { _tasks = value; }
		}

		private int _id;

		public int id {
			get { return _id; }
			set { _id = value; }
		}

		private string _name;

		public string name {
			get { return _name; }
			set { _name = value; }
		}
	}

	public class Task : Object {
		private int _id;

		public int id {
			get { return _id; }
			set { _id = value; }
		}

		private string _name;

		public string name {
			get { return _name; }
			set { _name = value; }
		}
	}

	public class Application : Gtk.Application {

		Gtk.Window window;
		Gtk.Box box;
		Gtk.Toolbar toolbar;
		Gtk.ToggleToolButton authentication;
		Gtk.ToolButton about;
		Gtk.ToolButton start;
		Gtk.ToolButton pause;
		Gtk.ToolButton stop;
		Gtk.Label time;
		Gtk.Entry comment;
		Gtk.Entry subdomain;
		Gtk.Entry email;
		Gtk.Entry password;

		bool paused = false;
		string harvest_subdomain;
		string harvest_email;
		string harvest_password;
		int harvest_project;
		int harvest_task;
		int harvest_entry;
		Timer timer;
		uint timeout;

		ComboBoxText project;
		ComboBoxText task;
		Gtk.Label status;

		string VERSION = "0.1.1";

		private ArrayList<Project?> projects;

		public Application() {
			GLib.Object(application_id: "tkowalewski.harvest.gtk",flags: ApplicationFlags.FLAGS_NONE);
		}

		public static int main (string[] args) {
			//Gtk.init(ref args);
			return new Application().run(args);
		}

		protected override void activate() {
			projects = new ArrayList<Project?>();
			window = new Gtk.Window();
			window.set_title("Harvest");
			window.default_width = 250;
			window.window_position = Gtk.WindowPosition.CENTER;
			//window.destroy.connect(() => Gtk.main_quit());
			
			box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);

			toolbar = new Gtk.Toolbar();
			toolbar.toolbar_style = Gtk.ToolbarStyle.ICONS;
			toolbar.set_icon_size(Gtk.IconSize.SMALL_TOOLBAR);

			subdomain = new Gtk.Entry();
			subdomain.placeholder_text = "subdomain";
			email = new Gtk.Entry();
			email.placeholder_text = "email@domain.tld";
			password = new Gtk.Entry();
			password.placeholder_text = "password";
			password.set_visibility(false);

			authentication = new Gtk.ToggleToolButton.from_stock(Gtk.Stock.DIALOG_AUTHENTICATION);
			authentication.clicked.connect(on_authentication_toggle);

			about = new Gtk.ToolButton.from_stock (Gtk.Stock.DIALOG_INFO);
			about.clicked.connect(on_about_clicked);
			
			Gtk.ToolItem spacer = new Gtk.ToolItem();
			spacer.set_expand(true);
			time = new Gtk.Label("00:00:00");
			spacer.add(time);

			start = new Gtk.ToolButton.from_stock(Gtk.Stock.MEDIA_PLAY);
			start.clicked.connect(on_start_clicked);
			pause = new Gtk.ToolButton.from_stock(Gtk.Stock.MEDIA_PAUSE);
			pause.clicked.connect(on_pause_clicked);
			stop = new Gtk.ToolButton.from_stock(Gtk.Stock.MEDIA_STOP);
			stop.clicked.connect(on_stop_clicked);

			toolbar.insert(start, -1);
			toolbar.insert(pause, -1);
			toolbar.insert(stop, -1);
			toolbar.insert(spacer, -1);
			toolbar.insert(authentication, -1);
			toolbar.insert(about, -1);

			project = new ComboBoxText();
			project.append("0", "Select project");
			project.active = 0;
			project.changed.connect(on_project_changed);

			task = new ComboBoxText();
			task.append("0", "Select task");
			task.active = 0;
			task.changed.connect(on_task_changed);

			comment = new Gtk.Entry();

			status = new Gtk.Label("");
			status.justify = Gtk.Justification.LEFT;

			box.pack_start(subdomain, false, false, 0);
			box.pack_start(email, false, false, 0);
			box.pack_start(password, false, false, 0);
			box.pack_end(status, false, false, 0);
			box.pack_end(toolbar, false, false, 0);
			

			window.add(box);

			box.show();
			subdomain.show();
			email.show();
			password.show();
			toolbar.show();
			authentication.show();
			about.show();
			spacer.show();
			status.show();
			window.show();

			timer = new Timer();

			this.add_window(window);
		}

		public void on_about_clicked() {
			var link = new Gtk.LinkButton("https://github.com/tkowalewski/harvest-gtk");
			link.activate_link();
		}

		public void on_authentication_toggle() {
			if (!authentication.active) {
					
				box.pack_start(subdomain, false, false, 0);
				box.pack_start(email, false, false, 0);
				box.pack_start(password, false, false, 0);
				if (project != null) {
					box.remove(project);
				}
				if (task != null) {
					box.remove(task);
				}
				if (comment != null) {
					box.remove(comment);
				}
				if (start != null) {
					start.hide();
				}
				if (pause != null) {
					pause.hide();
				}
				if (stop != null) {
					stop.hide();
				}
				if (time != null) {
					time.hide();
				}

				subdomain.show();
				email.show();
				password.show();
				
			} else {
				status.label = "Please wait. Loading ...";
				harvest_subdomain = subdomain.get_text();
				harvest_email = email.get_text();
				harvest_password = password.get_text();
				if (!request_daily()) {
					authentication.set_active(false);
					status.label = "";
					alert("Can not connect!");
					return;
				}
				box.pack_start(project, false, false, 0);
				box.pack_start(task, false, false, 0);
				box.pack_start(comment, false, false, 0);
				box.remove(subdomain);
				box.remove(email);
				box.remove(password);
				start.show();
				pause.show();
				stop.show();
				time.show();
				project.show();
				task.show();
				comment.show();
				status.label = "";
			}
		}

		public void on_project_changed() {
			if (project.active > 0) {
				task.remove_all();
				task.append("0", "Select task");
				task.active = 0;
				harvest_project = int.parse(project.get_active_id());
				foreach(Project _p in projects) {
					if (_p.id == harvest_project) {
						foreach(Task _t in _p.tasks) {
							task.append(_t.id.to_string(), _t.name);
						}
						break;
					}
				}
				harvest_task = 0;
				task.set_sensitive(true);
			} else {
				harvest_project = 0;
				harvest_task = 0;
				task.remove_all();
				task.append("0", "Select task");
				task.active = 0;
				task.set_sensitive(false);
			}
		}

		public void on_task_changed() {
			if (task.active > 0 ) {
				harvest_project = int.parse(project.get_active_id());
				harvest_task = int.parse(task.get_active_id());
				start.set_sensitive(true);
				comment.set_sensitive(true);
				comment.set_text("");
				pause.set_sensitive(false);
				stop.set_sensitive(false);
			} else {
				harvest_project = int.parse(project.get_active_id());
				harvest_task = 0;
				start.set_sensitive(false);
				pause.set_sensitive(false);
				stop.set_sensitive(false);
				comment.set_text("");
				comment.set_sensitive(false);
			}
		}

		public void on_start_clicked() {
			status.label = "Please wait. Starting ...";
			if (paused) {
				if (!request_toggle()) {
					status.label = "";
					alert("Can not unpause!");
					return;
				}
			} else {
				if (!request_create()) {
					status.label = "";
					alert("Can not start!");
					return;
				}
			}

			project.set_sensitive(false);
			task.set_sensitive(false);
			start.set_sensitive(false);
			comment.set_sensitive(false);
			pause.set_sensitive(true);
			stop.set_sensitive(true);
			if (paused) {
				paused = false;
				timer.@continue();
			} else {
				timer.start();
			}
			timeout = Timeout.add_seconds(1, on_timer_event);
			status.label = "";
		}

		public void on_pause_clicked() {
			status.label = "Please wait. Pausing ...";
			if (!request_toggle()) {
				status.label = "";
				alert("Can not pause!");
				return;
			}
			paused = true;
			pause.set_sensitive(false);
			stop.set_sensitive(false);
			start.set_sensitive(true);
			timer.stop();
			status.label = "";
		}

		public void on_stop_clicked() {
			status.label = "Please wait. Stopping ...";
			if (!request_toggle()) {
				status.label = "";
				alert("Can not stop!");
				return;
			}
			project.set_sensitive(true);
			task.set_sensitive(true);
			start.set_sensitive(true);
			pause.set_sensitive(false);
			stop.set_sensitive(false);
			comment.set_sensitive(true);
			Source.remove(timeout);
			time.set_label("00:00:00");
			timer.stop();
			status.label = "";
		}

		public bool on_timer_event() {
			double seconds = timer.elapsed();
			int num = (int)seconds;
			time.set_label("%s".printf(seconds_to_full_string(num)));
			return true;
		}

		public string seconds_to_full_string (uint seconds) {
			var hours = (seconds / (60 * 60));
			var minutes = (seconds / 60) - (hours * 60);
			seconds = seconds % 60;
			string h;
			string m;
			string s;
			if (hours < 10) {
				h = "0%s".printf(hours.to_string());
			} else {
				h = hours.to_string();
			}
			if (minutes < 10) {
				m = "0%s".printf(minutes.to_string());
			} else {
				m = minutes.to_string();
			}
			if (seconds < 10) {
				s = "0%s".printf(seconds.to_string());
			} else {
				s = seconds.to_string();
			}
			return "%s:%s:%s".printf(h, m, s);
		}

		public void alert(string message) {
			var dialog = new Gtk.MessageDialog(window,Gtk.DialogFlags.MODAL,Gtk.MessageType.OTHER, Gtk.ButtonsType.OK, "");
			dialog.modal = true;
			dialog.text = message;
			dialog.set_transient_for(window);
			dialog.run();
			dialog.destroy();
		}

		public bool request_daily() {
			Xml.Doc* response =  request("daily");
			if (response == null) {
				return false;
			}
			Xml.Node* rootNode = response->get_root_element();
			for(Xml.Node* i1 = rootNode->children; i1 != null; i1 = i1->next) {
				if(i1->type != ElementType.ELEMENT_NODE) {
					continue;
				}
				if(i1->name == "projects") {
					Xml.Node *i2;
					for(i2 = i1->children->next; i2 != null; i2 = i2->next) {
						if(i2->type != ElementType.ELEMENT_NODE) {
							continue;
						}
						if (i2->name == "project") {
							Project p = new Project();
							ArrayList<Task?> _t = new ArrayList<Task?>();
							Xml.Node *i3;
							for(i3 = i2->children->next; i3 != null; i3 = i3->next) {
								if(i3->is_text() != 1) {
									switch(i3->name) {
										case "name":
											p.name = i3->get_content();
										break;

										case "id":
											p.id = int.parse(i3->get_content());
										break;

										case "tasks":
											Xml.Node *i4;
											for(i4 = i3->children->next; i4 != null; i4 = i4->next) {
												if(i4->type != ElementType.ELEMENT_NODE) {
													continue;
												}
												if (i4->name == "task") {
													Task t = new Task();
													Xml.Node *i5;
													for(i5 = i4->children->next; i5 != null; i5 = i5->next) {
														if(i5->is_text() != 1) {
															switch(i5->name) {
																case "name":
																	t.name = i5->get_content();
																break;

																case "id":
																	t.id = int.parse(i5->get_content());
																break;
															}
														}
													}
													delete i5;
													_t.add(t);
												}
											}
											delete i4;
										break;
									}
								}
							}
							delete i3;
							p.tasks = _t;
							projects.add(p);
						}
					}
					delete i2;
				}
			}
			foreach(Project p in projects) {
				project.append(p.id.to_string(), p.name);
			}
			return true;
		}

		public bool request_create() {
			string xml = "<request><notes>%s</notes><hours></hours><project_id>%s</project_id><task_id>%s</task_id></request>".printf(comment.get_text(), harvest_project.to_string(), harvest_task.to_string());
			Xml.Doc* response =  request("daily/add", xml);
			if (response == null) {
				return false;
			}
			Xml.XPath.Context* xpath = new Xml.XPath.Context(response);
			Xml.XPath.Object* result = xpath->eval("string(/add/day_entry/id)");
			harvest_entry = int.parse(result->stringval);
			return true;
		}

		public bool request_toggle() {
			string action = "daily/timer/%s".printf(harvest_entry.to_string());
			Xml.Doc* response =  request(action);
			if (response == null) {
				return false;
			}
			Xml.XPath.Context* xpath = new Xml.XPath.Context(response);
			Xml.XPath.Object* result = xpath->eval("string(/timer/day_entry/id)");
			if (harvest_entry.to_string() == (string)result->stringval) {
				return true;
			}
			return false;
		}

		public unowned Xml.Doc request(string action, string xml = "") {
			string url = "https://%s.harvestapp.com/%s".printf(harvest_subdomain, action);
			string method = "GET";
			int status = 200;
			if (xml.length > 0) {
				method = "POST";
			}
			var session = new Soup.SessionAsync();
			var message = new Soup.Message (method, url);
			message.set_http_version(Soup.HTTPVersion.1_1);
			
			message.request_headers.append("Content-Type", "application/xml");
			message.request_headers.append("Accept", "application/xml");
			message.request_headers.append("User-Agent", "Harvest-Gtk %s".printf(VERSION));

			string authorization = Base64.encode("%s:%s".printf(harvest_email, harvest_password).data);
			message.request_headers.append("Authorization", "Basic %s".printf(authorization));

			if (method == "POST") {
				status = 201;
				StringBuilder body = new StringBuilder(xml);
				message.set_request( "application/xml", MemoryUse.COPY, body.data);
			}

			if (session.send_message(message) != status) {
				new Xml.Doc();
			}
			session.abort();
			return Xml.Parser.parse_doc((string)message.response_body.flatten().data);
		}

	}

}