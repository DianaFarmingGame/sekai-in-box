class_name TDBVal extends MonoTrait

var id := &"db_val"

var requires := [&"database"]

var props := {
	&"on_ready": Prop.puts({
		&"0:val_init": func(ctx, this: Mono):
			var vals = await sekai.db.callm(sekai.context, "db/getg", &"vals")
			if vals != null: for key in vals:
				if not this.applymRSUY(ctx, &"db/has", [key, &"vals"]):
					this.applymRSUY(ctx, &"db/set", [key, vals[key], &"vals"])
			,
	}),

}

