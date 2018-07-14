#Import "<mojo>"
#Import "<std>"

Using mojo..
Using std..

' Classes:
Class InputTest Extends Window
	' Aliases:
	Alias Time_t:Int
	Alias Duration_t:Int
	
	Alias DurationData_t:Deque<TimeState>
	
	' Constant variable(s):
	Const MAX_DATA_SAMPLE:= 30 ' 10
	
	Struct GraphOptions
		' Constant variable(s):
		Const DefaultOptions:= GetDefaults()
		Const Minimal:= GetMinimal()
		
		' Functions:
		Function GetDefaults:GraphOptions()
			Return New GraphOptions()
		End
		
		Function GetMinimal:GraphOptions()
			Local options:= GetDefaults()
			
			'options.x_line = False
			'options.y_line = False
			
			'options.point_markers = False
			options.index_markers = False
			options.axis_markers = False
			options.display_values = False
			
			Return options
		End
		
		' Fields:
		Field x_line:Bool = True
		Field y_line:Bool = True

		Field point_markers:Bool = True
		
		Field index_markers:Bool = True
		Field index_starts_at_zero:Bool = False ' True
		
		Field display_values:Bool = True
		
		Field connecting_lines:Bool = True
		
		Field axis_markers:Bool = True
		
		Field point_radius:Float = 4.0
		
		Field point_color:Color = Color.Blue
		Field connecting_line_color:Color = Color.Red
		Field axis_line_color:Color = Color.White
		Field text_color:Color = Color.White
	End
	
	' Constructor(s):
	Method New()
		Super.New("Input Test", 1280, 600, WindowFlags.Resizable)
	End
	
	' Methods:
	Method OnRender:Void(canvas:Canvas) Override
		App.RequestRender()
		
		OnUpdate()
		
		canvas.Clear(Color.Black) ' Color.LightGrey
		
		Const margin:= New Vec2f(24, 32)
		
		canvas.PushMatrix()
		
		canvas.Translate(margin.x, margin.y)
		
		If (Not duration_data.Empty) Then
			' Could be pre-computed when the data set changes, rather than every frame:
			Local largest_duration:Duration_t = TimeState.MaxValue(duration_data).duration ' Max<TimeState, DurationData_t>(data)
			Local median_duration:Duration_t = TimeState.MedianDuration(duration_data)
			
			Local graph_options:= GraphOptions.DefaultOptions ' Minimal
			
			DrawGraph(canvas, Self.Width - (margin.x * 2), Self.Height - (margin.y * 2), duration_data, largest_duration, median_duration, graph_options)
		Endif
		
		canvas.PopMatrix()
		
		canvas.DrawText("Mouse down: " + mouse_info.Duration, 8.0, 8.0, 0.0, 0.5)
	End
	
	Method DrawGraph:Void(canvas:Canvas, width:Float, height:Float, data:DurationData_t, max_value:Duration_t, median_value:Duration_t=Null, options:GraphOptions=GraphOptions.DefaultOptions)
		Local canvas_color:= canvas.Color
		
		Local data_length:= data.Length
		Local data_length_f:= data_length
		
		Local last_index:= (data_length - 1)
		Local last_index_f:= Float(last_index)
		
		Local max_value_f:= Float(max_value)
		Local median_value_f:= Float(median_value)
		
		Local half_height:= (height * 0.5)
		Local half_width:= (width * 0.5)
		
		If (options.x_line) Then
			Local y:Float
			
			If (median_value = Null) Then
				y = height
			Else
				y = half_height
			Endif
			
			canvas.Color = options.axis_line_color
			
			canvas.PushMatrix()
			
			canvas.Translate(0.0, y)
			
			canvas.DrawLine(0.0, 0.0, width, 0.0)
			
			canvas.Color = options.text_color
			
			canvas.DrawText("X", 0.0, 0.0, 0.0, 1.5)
			
			canvas.PopMatrix()
		Endif
		
		If (options.y_line) Then
			Local x:Float
			
			If (median_value = Null) Then
				x = width
			Else
				x = half_width
			Endif
			
			canvas.PushMatrix()
			
			canvas.Translate(x, 0.0)
			
			canvas.Color = options.axis_line_color
			
			canvas.DrawLine(0.0, 0.0, 0.0, height)
			
			canvas.Color = options.text_color
			
			canvas.DrawText("Y", 0.0, 0.0, 1.5, 0.0)
			
			canvas.PopMatrix()
		Endif
		
		canvas.Color = canvas_color
		
		Local previous_point:Vec2f = Null
		
		For Local i:= 0 Until data_length
			Local entry:= data[i]
			Local has_connected_entry:= (i > 0)
			
			Local duration:= entry.duration
			Local duration_f:= Float(duration)
			
			Local x:Float
			Local y:Float
			
			Local index_scalar:= (Float(i) / last_index_f)
			
			x = (width * index_scalar)
			
			If (median_value = Null) Then
				y = (height - (height * (duration_f / max_value_f)))
			Else
				y = half_height
				
				y -= ((duration_f - median_value_f) / max_value_f) * half_height
			Endif
			
			Local point:= New Vec2f(x, y)
			
			'Print("Point[" + i + "]: " + point)
			
			If (options.point_markers) Then
				canvas.Color = options.point_color
				
				canvas.DrawCircle(point.x, point.y, options.point_radius)
			Endif
			
			If (has_connected_entry) Then
				If (options.connecting_lines) Then
					canvas.Color = options.connecting_line_color
					
					canvas.DrawLine(previous_point, point)
				Endif
			Endif
			
			If (options.index_markers) Then
				Local display_index:= i
				
				If (Not options.index_starts_at_zero) Then
					display_index += 1
				Endif
				
				canvas.Color = options.text_color
				
				canvas.DrawText(String(display_index), point.x, point.y, 0.5, 0.5)
			Endif
			
			If (options.display_values) Then
				canvas.Color = options.text_color
				
				Local handle:= New Vec2f(0.5, 0.5)
				
				If (options.index_markers) Then
					handle.y = 1.5
				Endif
				
				canvas.DrawText(String(duration) + "ms", point.x, point.y, handle.x, handle.y)
			Endif
			
			previous_point = point
		Next
		
		canvas.Color = canvas_color
	End
	
	Method OnUpdate:Void()
		Local press_finished:= mouse_info.Poll()
		
		If (press_finished) Then
			If (MAX_DATA_SAMPLE > 0) Then
				While (duration_data.Length >= MAX_DATA_SAMPLE)
					duration_data.PopFirst()
				Wend
			Endif
			
			duration_data.PushLast(mouse_info.Time) ' Add
		Endif
	End
	
	' Classes / Structures:
	Class MouseInfo ' Struct
		Public
			' Constructor(s):
			Method New()
				' Initialize default state:
				UpdateTimestamp()
				UpdateDuration()
			End
			
			' Methods:
			Method Poll:Bool()
				Local current_state:= Mouse.ButtonDown(MouseButton.Left)
				Local press_complete:Bool = False
				
				If (Self.Down And Not current_state) Then
					press_complete = True
				Endif
				
				Self.Down = current_state
				
				Return press_complete
			End
			
			Method UpdateTimestamp:Time_t()
				Self.time_state.time_stamp = TimeState.Current()
				
				Return Self.time_state.time_stamp
			End
			
			Method UpdateDuration:Duration_t()
				Self.time_state.duration = (TimeState.Current() - Timestamp)
				
				Print("Duration is: " + Self.time_state.duration)
				
				Return Self.time_state.duration
			End
			
			' Properties:
			Property Timestamp:Time_t()
				Return Self.time_state.time_stamp
			End
			
			Property Duration:Duration_t()
				If (Down) Then
					Return UpdateDuration()
				Endif
				
				Return Self.time_state.duration
			End
			
			Property Time:TimeState()
				Return Self.time_state
			End
			
			Property Down:Bool()
				Return Self.down
			Setter(value:Bool)
				If (Self.down <> value) Then ' <> True
					UpdateTimestamp()
					
					Print("Time stamp updated to: " + Timestamp)
					
					Print("Mouse down changed: " + String(value))
				Endif
				
				Self.down = value
			End
		Private
			' Fields:
			Field time_state:TimeState
			
			Field down:Bool = False
	End
	
	Struct TimeState
		' Functions:
		Function Current:Time_t()
			'Return Time.Now()
			Return Millisecs()
		End
		
		Function MinValue:TimeState(data:DurationData_t)
			Local min_value:= data[0]
			
			For Local value:= Eachin data
				If (value.duration < min_value.duration) Then
					min_value = value
				Endif
			Next
			
			Return min_value
		End
		
		Function MaxValue:TimeState(data:DurationData_t)
			Local max_value:= data[0]
			
			For Local value:= Eachin data
				If (value.duration > max_value.duration) Then
					max_value = value
				Endif
			Next
			
			Return max_value
		End
		
		Function MedianDuration:Duration_t(data:DurationData_t)
			Local sum:Duration_t
			
			For Local value:= Eachin data
				sum += value.duration
			Next
			
			Return (sum / data.Length)
		End
		
		' Operator(s):
		#Rem
		Operator<=>:Int(state:TimeState)
			Return (duration <=> state.duration)' (time_stamp <=> state.time_stamp)
		End
		#End
		
		' Fields:
		Field time_stamp:Time_t
		Field duration:Duration_t
	End
	
	' Fields:
	Field mouse_info:= New MouseInfo()
	Field duration_data:= New DurationData_t()
End

#Rem
Function Max<T, Container_t>:T(values:Container_t)
	Return Filter(values, Lambda:T(x:T, y:T)
		If (x > y) Then
			Return x
		Endif
		
		Return y
	End)
End

Function Min<T, Container_t>:T(values:Container_t)
	Return Filter<Container_t, T>(values, Lambda:T(x:T, y:T)
		If (x < y) Then
			Return x
		Endif
		
		Return y
	End)
End

' Prefer the newer object over the older one.
' (This comparison is useful for value semantics, objects see no difference)
Function Latest<T, Container_t>:T(values:Container_t)
	Return Filter<Container_t, T>(values, Lambda:T(x:T, y:T)
		If (x = y) Then
			Return x
		Endif
		
		Return y
	End)
End

Function Filter<Container_t, T>:T(values:Container_t, Pred:T(T, T))
	DebugAssert((values.Length > 0), "Expected at least one value")
	
	Local state:= values[0]
	
	For Local x:= Eachin values
		state = Pred(x, state)
	Next
	
	Return state
End
#End

Function Main:Void()
	New AppInstance()
	
	New InputTest()
	
	App.Run()
End