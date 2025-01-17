/**
* Name: DXF to Agents Model
* Author:  Arnaud Grignard
* Description: Model which shows how to create agents by importing data of a DXF file
* Tags:  dxf, load_file
*/
model DXFAgents

import "../CurrentModels/Constants.gaml"


global
{
	//define the path to the dataset folder
	
	string dataset_path <- "./../../includes/";
	string useCase;
	//Parameters used onyl for video editing
	string title<-"default";
	string ventilationType<-"default";
	float timeSpent<-1.0 #hour;
	file the_dxf_metadata <- file_exists(dataset_path + useCase +"/building.csv") ?csv_file(dataset_path + useCase +"/building.csv",",",true) : nil;
	float unit <- (the_dxf_metadata != nil )? float(matrix(the_dxf_metadata)[1,0]) : #cm;
	//define the bounds of the studied area
	file the_dxf_file <- dxf_file(dataset_path + useCase +"/building.dxf",unit);
	bool validator<-true;
	geometry shape <- envelope(the_dxf_file);
	
	// Defining the mandatory layer
	map<string,rgb> standard_color_per_layer <- 
	[offices::#gamablue,meeting_rooms::#blue,library::#dodgerblue,lab::#midnightblue,
	entrance::#fuchsia,elevators::#pink,stairs::#lightpink,
	furnitures::#maroon,chairs::#orangered,
	toilets::#darkslategray,  sanitation::#seagreen, 
	coffee::#mintcream,
	walls::#white, windows::#white,doors::#white];
	
	bool showLegend<-true;
	
	list<string> existing_types;
	list<string> missing_type_elements;
	list<string> useless_type_elements;
	
	action initiliaze_dxf
	{  
		 if(validator){
			existing_types <- remove_duplicates(the_dxf_file.contents collect (each get layer));
			missing_type_elements <- standard_color_per_layer.keys - existing_types;
			useless_type_elements <- (existing_types -  standard_color_per_layer.keys);
			if (not empty(missing_type_elements) or not empty(useless_type_elements)) {
				if (not empty(missing_type_elements)) {
						do tell("Use Case: "+ useCase + "\n\nExisting layers: " + existing_types+ 
						"\n\nMissing layers:  " + missing_type_elements +  
					    (empty(useless_type_elements) ? "" :("\n\nUseless layers:" + useless_type_elements)));
				} else {
					do tell("Some elements (layers) will not be used by the model:" + useless_type_elements);
				}
			
			}
		}
		create dxf_element from: the_dxf_file with: [layer::string(get(layer))];
		map layers <- list(dxf_element) group_by each.layer;
		loop la over: layers.keys
		{
			rgb col <- rnd_color(255);
			ask layers[la]
			{
				if(standard_color_per_layer.keys contains la){
				   color <- standard_color_per_layer[la];
				}else{
					color <-#gray;
					useless<-true;
				}
			}
		}
		ask dxf_element{
			if (useless){
				 if(validator){write "this element cannot be used and will be removed " + name + " layer: " + layer;}
				do die;
			}
		}
	}
}

species dxf_element
{
	string layer;
	rgb color <- #black;
	bool useless;
	list<point> entrances;
	
	aspect default
	{
		draw shape color: standard_color_per_layer[layer];
		loop e over: entrances {
			draw square(0.5) at: e color: #magenta;
		}
	}
	init {
		shape <- polygon(shape.points);
	}
}

experiment DXFDisplay type: gui virtual:true
{   parameter 'fileName:' var: useCase category: 'file' <- "MediaLab" among: ["Factory", "MediaLab","Hotel-Dieu","ENSAL"];
	
	
	output
	{	layout #split;
		display floorPlan type: opengl virtual:true toolbar:false
		{
			species dxf_element position:{0,0,-0.01};
			graphics 'legend' {
			if(showLegend){	
			  point legendPos<-{-world.shape.width*0.3,0};
			  float verticalSpace <- world.shape.width * 0.015;
			  float horizontalSpace <- world.shape.width * 0.15;
			  float squareSize<-world.shape.width*0.02;
			  loop i from:0 to:length(standard_color_per_layer)-1{
                point curPos<-{(i mod 2) * horizontalSpace,((i mod 2 = 1)  ? i*verticalSpace : (i+1)*verticalSpace)+ world.shape.height/4};
				//draw square(squareSize) color: standard_color_per_layer.values[i] at: legendPos+ curPos;
				draw string(standard_color_per_layer.keys[i]) + ": " +length (dxf_element where (each.layer= standard_color_per_layer.keys[i]))color: standard_color_per_layer.values[i] at: {curPos.x-30#px,curPos.y+verticalSpace}+legendPos perspective: true font:font("Helvetica", 20 , #bold);
			  }
			}
			}
			
			
		}

		
	}
}