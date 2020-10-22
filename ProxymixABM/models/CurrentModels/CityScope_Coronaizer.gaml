/***
* Name: CityScope Epidemiology
* Author: Arnaud Grignard
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model CityScopeCoronaizer

import "DailyRoutine.gaml"

global{
	bool fixed_infected_people_localization <- true;
	bool direct_infection <- true;
	bool objects_infection <- true;
	bool air_infection <- true;
	float infectionDistance <- 1#m;
	float maskRatio <- 0.0;
	float direct_infection_factor<-0.05; //increasement of the infection risk per second
	
	float indirect_infection_factor<-0.003; //increasement of the viral load of cells per second 
	float basic_viral_decrease_cell <- 0.0003; //decreasement of the viral load of cells per second 
	float mask_indirect_infection_factor<-0.25;// Effect of the mask on the air transmission
	
	
	float air_infection_factor <- 0.0005; //decreasement of the viral load of cells per second 
	float basic_viral_decrease_room <- 0.0001; //decreasement of the viral load of cells per second 
	float ventilated_viral_decrease_room <- 0.001; //decreasement of the viral load of cells per second 
	float mask_air_infection_factor<-0.25;// Effect of the mask on the air transmission
	
	float diminution_cumulated_viral_load_sanitation <- 0.1;
	float hand_cleaning_time_effect <- 1#h;
	float diminution_cumulated_viral_load_mask_emission <- 0.7; //1.0 masks are totaly efficient to avoid direct transmission
	float diminution_cumulated_viral_load_mask_reception <- 0.7; //1.0 masks are totaly efficient to avoid direct transmission
	float diminution_cumulated_viral_load_separator <- 0.9;
	
    //float step<-1#mn;
	int totalNbInfection;
   	int initial_nb_infected<-10;
   	map<room, int> infected_per_room;
   	float Low_Risk_of_Infection_threshold<-30.0;
   	float Medium_Risk_of_Infection_threshold<-60.0;
	
	bool draw_viral_load_by_touching_grid<-false;
	bool draw_viral_load_per_room<-true;
	bool showPeople<-true;
	
	int nb_cols <- int(75*1.5);
	int nb_rows <- int(50*1.5);
	
	int nb_susceptible  <- 0 update: length(ViralPeople where (each.is_susceptible));
	int nb_infected <- 0 update: length(ViralPeople where (each.is_infected));
	int nb_recovered <- 0 update: length(ViralPeople where (each.is_recovered));
	
	list<ViralPeople> infectionRiskList;
	
	init{		
	}
		
	reflex initCovid when:cycle = 1{
		if fixed_infected_people_localization {
			int nb_i;
			list<ViralPeople> concerned_people <- ViralPeople where (each.target.working_desk != nil);
			map<room,list<ViralPeople>> pp_per_room <- concerned_people group_by each.target.working_place;
			list<room> r_ord <- pp_per_room.keys  sort_by each.name;
			int direction_i <- 0;
			float sum_area <- r_ord sum_of each.shape.area;
			loop r over: r_ord {
				list<ViralPeople> pps <- pp_per_room[r];
				int nb_infected_room <- round(initial_nb_infected * r.shape.area/ sum_area);
				nb_infected_room <- min([nb_infected_room, initial_nb_infected - nb_i, length(pps)]);
				if nb_infected_room > 0 and not empty(pps){
					int direction <- direction_i;
					loop times: nb_infected_room {
						ViralPeople vp;
						if direction = 0 {
							vp <- pps with_min_of (each.target.working_desk.location distance_to each.target.working_place.location);
						}else if direction = 1 {
							vp <- (pps sort_by (each.target.working_desk.location.y - each.target.working_desk.location.x)) [min(4, length(pps) - 1)];
						} else if direction = 2 {
							vp <- (pps sort_by (each.target.working_desk.location.x - each.target.working_desk.location.y)) [min(2, length(pps) - 1)];
						} else {
							vp <- pps with_max_of (each.target.working_desk.location distance_to each.target.working_place.location);
						}
						ask vp{
							has_been_infected<-true;
							is_susceptible <-  false;
					        is_infected <-  true;
					        is_immune <-  false;
					        is_recovered<-false;
					        pps >> self;
						}
						direction <- (direction + 1 ) mod 4;
					}
					pp_per_room[r] <- pps;
					nb_i <- nb_i + nb_infected_room;
				}
				direction_i <- (direction_i + 1) mod 4;
				
				
			}
			if nb_i < initial_nb_infected {
				list<room> ror <- pp_per_room.keys sort_by each.name;
				
				int direction <- 0;
				
				loop while: nb_i < initial_nb_infected {
					loop r over: ror {
						if (nb_i = initial_nb_infected) {
							break;
						} else {
							list<ViralPeople> pps <- pp_per_room[r];
							if (not empty(pps))  {
								ViralPeople vp;
								
								if direction = 0 {
									vp <- pps with_min_of (each.target.working_desk.location distance_to each.target.working_place.location);
								}else if direction = 1 {
									vp <- (pps sort_by (each.target.working_desk.location.y - each.target.working_desk.location.x)) [min(4, length(pps) - 1)];
								} else if direction = 2 {
									vp <- (pps sort_by (each.target.working_desk.location.x - each.target.working_desk.location.y)) [min(2, length(pps) - 1)];
								} else {
									vp <- pps with_max_of (each.target.working_desk.location distance_to each.target.working_place.location);
								}
								ask vp{
									has_been_infected<-true;
									is_susceptible <-  false;
							        is_infected <-  true;
							        is_immune <-  false;
							        is_recovered<-false;
							        pps >> self;
								}
								direction <- (direction + 1 ) mod 4;
							
								pp_per_room[r] <- pps;
								nb_i <- nb_i + 1;
							}
						}
					}
				}
			}
			
		} else {
			ask initial_nb_infected among ViralPeople{
				has_been_infected<-true;
				is_susceptible <-  false;
				is_infected <-  true;
				is_immune <-  false;
				is_recovered<-false;
			}
		}
		
	}
}


species ViralBuildingEntrance mirrors: building_entrance parent: ViralRoom ;

species ViralCommonArea mirrors: common_area parent: ViralRoom ;

species ViralRoom mirrors: room {
	list<rgb> room_color_map<-[rgb(109, 112, 0),rgb(175, 190, 49),rgb(211, 186, 25),rgb(247, 181, 0),rgb(246, 143, 18),rgb(245, 105, 36),rgb(244, 67, 54)];	
	float viral_load min: 0.0 max: 10.0;
	init {
		shape <- target.shape;
	}
	
	reflex update_viral_load when: air_infection{
		if (target.isVentilated) {
			viral_load <- viral_load * (1-ventilated_viral_decrease_room)^ step;
		} else {
			viral_load <- viral_load * (1-basic_viral_decrease_room) ^ step;
		}
	}
	//Action to add viral load to the room
	action add_viral_load(float value){
		viral_load <- viral_load + (value/ shape.area);
	}
	
	aspect default {
		if(draw_viral_load_per_room){
		  if (air_infection) {
		  	//draw shape color: room_color_map[rnd(length(color_map))];//blend(color_map["red"], color_map["green"], viral_load*1000);//;blend(rgb(169,0,0), rgb(125,239,66), viral_load*1000); //blend(#red, #green, viral_load*1000);		
		  	//draw shape color: room_color_map[int(min (1,viral_load/0.1)*(length(color_map)-1))];//blend(color_map["red"], color_map["green"], viral_load*1000);//;blend(rgb(169,0,0), rgb(125,239,66), viral_load*1000); //blend(#red, #green, viral_load*1000);	
			draw shape color: blend(color_map["red"], color_map["green"], min(1,viral_load*1000));//;blend(rgb(169,0,0), rgb(125,239,66), viral_load*1000); //blend(#red, #green, viral_load*1000);
		}		
	 }
	}
}

species ViralPeople  mirrors:people{
	point location <- target.location update: {target.location.x,target.location.y,target.location.z};
	list<float> cumulated_viral_load<-[0.0,0.0,0.0];
	bool is_susceptible <- true;
	bool is_infected <- false;
    bool is_immune <- false;
    bool is_recovered<-false;
    float infected_time<-0.0;
    geometry shape<-circle(1); 
  	int nb_people_infected_by_me<-0;
    bool has_been_infected<-false;
    bool has_mask<-flip(maskRatio);
    float time_since_last_hand_cleaning update: time_since_last_hand_cleaning + step;


	reflex virus_propagation when: not target.not_yet_active and not target.end_of_day and is_infected and not target.is_outside and not target.using_sanitation {
		if (direct_infection) {
			ask (ViralPeople at_distance infectionDistance) where (not each.target.end_of_day and not target.not_yet_active and not each.is_infected and not each.target.using_sanitation and not each.target.is_outside) {
				geometry line <- line([myself,self]);
				if empty(wall overlapping line) {
					float effective_direct_infection_factor <- direct_infection_factor * step;
					if empty(separator_ag overlapping line) {
						effective_direct_infection_factor <- effective_direct_infection_factor * (1 - diminution_cumulated_viral_load_separator);
					}
					if myself.has_mask {
						effective_direct_infection_factor <- effective_direct_infection_factor * (1 - diminution_cumulated_viral_load_mask_emission);
					}
					if self.has_mask{
						effective_direct_infection_factor <- effective_direct_infection_factor * (1 - diminution_cumulated_viral_load_mask_reception);
					}
					cumulated_viral_load[0] <- cumulated_viral_load[0] + effective_direct_infection_factor;
				} 
			}
		}
		if (objects_infection) and (time_since_last_hand_cleaning < hand_cleaning_time_effect){
			ViralCell vc <- ViralCell(self.target.location);
			if (vc != nil) {
				ask (vc){
					do add_viral_load(myself.has_mask? mask_indirect_infection_factor*indirect_infection_factor * step:indirect_infection_factor * step);
				}
			}
		}
		if (air_infection) {
			ViralRoom my_room <- first(ViralRoom overlapping location);
			if (my_room != nil) {ask my_room{do add_viral_load(myself.has_mask ? mask_air_infection_factor*air_infection_factor * step : air_infection_factor * step);}}
			ViralCommonArea my_rca <- first(ViralCommonArea overlapping location);
			if (my_rca != nil) {ask my_rca{do add_viral_load(myself.has_mask ? mask_air_infection_factor*air_infection_factor * step : air_infection_factor * step);}}	
		}
	}
	
	reflex using_sanitation when: not target.not_yet_active and not target.end_of_day  and target.using_sanitation {
		cumulated_viral_load[1] <- cumulated_viral_load[1] * (1- diminution_cumulated_viral_load_sanitation)  ^ step;
		time_since_last_hand_cleaning <- 0.0;
	}
	reflex infection_by_objects when:not target.not_yet_active and not target.end_of_day and  objects_infection and not is_infected and not target.is_outside and not target.using_sanitation {
		ViralCell vrc <- ViralCell(location);
		if (vrc != nil) {cumulated_viral_load[1] <- cumulated_viral_load[1] + (self.has_mask? mask_indirect_infection_factor* step * vrc.viral_load_by_touching: step * vrc.viral_load_by_touching);}
	}
	reflex infection_by_air when: not target.not_yet_active and not target.end_of_day and air_infection and not is_infected and not target.is_outside and not target.using_sanitation {
		ViralRoom my_room <- first(ViralRoom overlapping location);
		if (my_room != nil) {cumulated_viral_load[2] <- cumulated_viral_load[2] + (self.has_mask ? mask_air_infection_factor* step * my_room.viral_load: step * my_room.viral_load);}
		ViralCommonArea my_rca <- first(ViralCommonArea overlapping location);
		if (my_rca != nil) {cumulated_viral_load[2] <- cumulated_viral_load[2] + (self.has_mask ? mask_air_infection_factor* step * my_room.viral_load: step * my_rca.viral_load);}
	}
			
	aspect base {
		if not target.end_of_day and not target.not_yet_active{
			if(showPeople) and not target.is_outside{
			  draw circle(peopleSize) color:(is_infected) ? color_map["blue"] : blend(color_map["red"], color_map["green"], sum(cumulated_viral_load)/100.0);					
				if (has_mask){
					draw square(peopleSize*0.5) color:#white border:rgb(70,130,180)-100;	
				}
			}
		}	
	}
}


grid ViralCell cell_width: 1.0 cell_height:1.0 neighbors: 8 {
	rgb color <- #white;
	
	float viral_load_by_touching min: 0.0 max: 10.0;
	//Action to add viral load to the cell
	action add_viral_load(float value){
		viral_load_by_touching <- viral_load_by_touching+value;
	}
	//Action to update the viral load (i.e. trigger decreases)
	reflex update_viral_load {
		viral_load_by_touching <- viral_load_by_touching * (1- basic_viral_decrease_cell) ^ step;
	}
	aspect default{
		if (draw_viral_load_by_touching_grid){
			if (viral_load_by_touching > 0){
				draw shape color:blend(#white, #red, viral_load_by_touching/1.0);		
			}
		}
	}	
}


grid cell cell_width: world.shape.width/100 cell_height:world.shape.width/100 neighbors: 8 {
	bool is_wall <- false;
	bool is_exit <- false;
	rgb color <- #white;
	float firstInfectionTime<-0.0;
	int nbInfection;	
}

experiment Coronaizer type:gui autorun:false{

	parameter 'title:' var: title category: 'Initialization' <- "Generic";
	parameter 'fileName:' var: useCase category: 'Initialization' <- "MediaLab" among: ["UDG/CUCS/Campus","UDG/CUSUR","UDG/CUCEA","UDG/CUAAD","UDG/CUT/campus","UDG/CUT/lab","UDG/CUT/room104","UDG/CUCS/Level 2","UDG/CUCS/Ground","UDG/CUCS_Campus","UDG/CUCS/Level 1","Factory", "MediaLab","CityScience","Learning_Center","ENSAL","SanSebastian"];
	parameter 'Episode:' var: episode category: 'Initialization' <- 0;
	parameter 'useCaseType:' var: useCaseType category: 'Initialization' <- "Generic";
	parameter 'ventilationType:' var: ventilationType category: 'Initialization' <- "Natural";
	parameter 'timeSpent:' var: timeSpent category: 'Initialization' <- 1.0 #h;
	parameter "Agenda Scenario:" category: 'Initialization' var: agenda_scenario  <-"simple";
	parameter "Initial Infected"   category: 'Initialization' var: initial_nb_infected min:0 max:100 <-10;
	parameter "Density Scenario" var: density_scenario category:'Policy'  <- "distance" among: ["data", "distance", "num_people_building", "num_people_room"];
	parameter 'distance people:' var: distance_people category:'Policy' min:0.0 max:5.0#m <- 2.0#m;
	parameter "Mask Ratio:" category: "Policy" var: maskRatio min: 0.0 max: 1.0 step:0.1 <-0.0;
	parameter "Queueing:" category: "Policy" var: queueing  <-false;
	parameter "Ventilated room ratio:" category: "Policy" var:ventilation_ratio min:0.0 max:1.0 <-0.0;
	parameter "People Size:" category: "Visualization" var: peopleSize  <-0.3#m;
	parameter "step_arrival" category:'Initialization' var: step_arrival <- 1#s;
	parameter "arrival_time_interval" category:'Initialization' var: arrival_time_interval <- 3 #mn;
	
	
	parameter "Infection distance:" category: "Corona" var:infectionDistance min: 1.0 max: 100.0 step:1;
	
	parameter "Draw Infection by Touching Grid:" category: "Risk Visualization" var:draw_viral_load_by_touching_grid;
	parameter "Draw Viral Load:" category: "Risk Visualization" var:draw_viral_load_per_room<-true;
	parameter "Show People:" category: "Visualization" var:showPeople;
    parameter 'People per Building (only working if density_scenario is num_people_building):' var: num_people_per_building category:'Initialization' min:0 max:1000 <- 10;
	parameter 'People per Room (only working if density_scenario is num_people_building):' var: num_people_per_room category:'Initialization' min:0 max:100 <- 10;
	parameter "Social Distance Graph:" category: "Visualization" var:drawSocialDistanceGraph ;
	parameter "Draw Flow Grid:" category: "Visualization" var:draw_flow_grid;
	parameter "Draw Proximity Grid:" category: "Visualization" var:draw_proximity_grid;
	parameter "Draw Pedestrian Path:" category: "Visualization" var:display_pedestrian_path;
	parameter "Show available desk:" category: "Visualization" var:showAvailableDesk <-false;
	parameter "Show bottlenecks:" category: "Visualization" var:show_dynamic_bottleneck <-false;
	parameter "Bottlenecks lifespan:" category: "Visualization" var:bottleneck_livespan min:0 max:100 <-10;
	parameter "Show droplets:" category: "Droplet" var:show_droplet <-false;
	parameter "Droplets lifespan:" category: "Droplet" var:droplet_livespan min:0 max:100 <-10;
	parameter "Droplets distance:" category: "Droplet" var:droplet_distance min:0.0 max:10.0 <-2.0;
		
	output{
	  layout #split;
	  display Simulation type:opengl  background:#black draw_env:false synchronized:false autosave:false	{
	   	species room  refresh: false;
		species room aspect: available_places_info refresh: true position:{0,0,0.001};
		species ViralRoom transparency:0.75 position:{0,0,0.001};
		species ViralCommonArea transparency:0.85 position:{0,0,0.001};
		species building_entrance refresh: true;
		species common_area refresh: true;
		species wall refresh: false;
		//species room_entrance;
		species pedestrian_path position:{0.0,0.0,0.01};
		species separator_ag refresh: false;
		agents "flowCell" value:draw_flow_grid ? flowCell : [] transparency:0.5 position:{0.0,0.0,0.01};
		agents "proximityCell" value:draw_proximity_grid ? proximityCell : [] position:{0.0,0.0,0.01};
		species bottleneck transparency: 0.5;
		species droplet aspect:base; 
	    species ViralPeople aspect:base position:{0,0,0.002};
	    species ViralCell aspect:default;
	
		graphics 'title'{
		  point titlePos;
		  if(episode=1){
		  	titlePos<-{world.shape.width*0.25,-400#px};
		  }else{
		  	titlePos<-{-world.shape.width*0.5,0};
		  }		
	 
		  draw "SCENARIO" color: #white at: {titlePos.x,titlePos.y,0.01} perspective: true font:font("Helvetica", 20 , #bold);
		  draw string(title) color: #white at: {titlePos.x,titlePos.y+50#px,0.01} perspective: true font:font("Helvetica", 40 , #plain);
		}
		graphics 'site'{
			  point sitlegendPos;
			  if(episode=1){
			  	sitlegendPos<-{world.shape.width*0,-300#px};
			  }else{
			  	sitlegendPos<-{-world.shape.width*0.5,world.shape.height*0.2};
			  }
			  int fontSize<-20;
			  draw string("SITE") color: #white at: {sitlegendPos.x,sitlegendPos.y,0.01} perspective: true font:font("Helvetica", fontSize*1.5 , #plain);
		      draw string(useCase) color: #white at: {sitlegendPos.x,sitlegendPos.y+fontSize#px,0.01} perspective: true font:font("Helvetica", fontSize , #bold); 
		      
		      draw string("Building type" ) color: #white at: {sitlegendPos.x,sitlegendPos.y+2*fontSize*1.5#px,0.01} perspective: true font:font("Helvetica", fontSize , #plain);
		      draw string(useCaseType ) color: #white at: {sitlegendPos.x,sitlegendPos.y+2*fontSize*1.5#px+fontSize#px,0.01} perspective: true font:font("Helvetica", fontSize , #bold);
		      
		      draw string("Floor area ") color: #white at: {sitlegendPos.x,sitlegendPos.y+4*fontSize*1.5#px,0.01} perspective: true font:font("Helvetica", fontSize , #plain); 
		      draw string("" + with_precision(totalArea,2) + "m2") color: #white at: {sitlegendPos.x,sitlegendPos.y+4*fontSize*1.5#px+fontSize#px,0.01} perspective: true font:font("Helvetica", fontSize , #bold); 		      
		}	
		 graphics "intervention"{
		 	point simLegendPos;
		 	if(episode=1){
		 		simLegendPos<-{world.shape.width*0.22,-300#px};
		 	}else{
		 	    simLegendPos<-{-world.shape.width*0.5,world.shape.height*0.6};	
		 	}	
	  		int fontSize<-20;
	  		draw "INTERVENTION" color:#white at:{simLegendPos.x,simLegendPos.y,0.01} perspective: true font:font("Helvetica", fontSize*1.5 , #plain);
	  		
	  		draw string("Physical distance") color: #white at: {simLegendPos.x,simLegendPos.y+2*fontSize*1.5#px,0.01} perspective: true font:font("Helvetica", fontSize , #plain);
	  		draw string(" " +  (density_scenario="data" ? "none" : with_precision(distance_people,2))) color: #white at: {simLegendPos.x,simLegendPos.y+2*fontSize*1.5#px+fontSize#px,0.01} perspective: true font:font("Helvetica", fontSize , #bold);
	  		
	  		draw "Masks" color: #white at: {simLegendPos.x,simLegendPos.y+4*fontSize*1.5#px,0.01} perspective: true font:font("Helvetica", fontSize , #plain); 
	  		draw "" + maskRatio*100 + "%" color: #white at: {simLegendPos.x,simLegendPos.y+4*fontSize*1.5#px+fontSize#px,0.01} perspective: true font:font("Helvetica", fontSize , #bold); 
	  		
	  		draw "Ventilation type "color:#white at:{simLegendPos.x,simLegendPos.y+6*fontSize*1.5#px,0.01} perspective: true font:font("Helvetica", fontSize , #plain);
	  		draw "" + ventilationType color:#white at:{simLegendPos.x,simLegendPos.y+6*fontSize*1.5#px+fontSize#px,0.01} perspective: true font:font("Helvetica", fontSize , #bold);
	  		
	  		draw "Time spent in classrooms"color:#white at:{simLegendPos.x,simLegendPos.y+8*fontSize*1.5#px,0.01} perspective: true font:font("Helvetica", fontSize , #plain);
			draw "" + timeSpent/#hour + "hr" color:#white at:{simLegendPos.x,simLegendPos.y+8*fontSize*1.5#px+fontSize#px,0.01} perspective: true font:font("Helvetica", fontSize , #bold);
	  	  	
	  	}
	  	
		graphics "time" {
		  point timeLegendPos;
		  if (episode = 1){
		  	timeLegendPos<-{world.shape.width*0,-50#px};
		  }else{
		  	timeLegendPos<-{world.shape.width*1.1,world.shape.height*0.1};
		  }
		  
	      draw "TIME" color: #white font: font("Helvetica", 20, #plain) at:{timeLegendPos.x,timeLegendPos.y,0.01};
	      draw string(current_date, "HH:mm:ss") color: #white font: font("Helvetica", 30, #bold) at:{timeLegendPos.x,timeLegendPos.y+30#px,0.01};
	      //draw string("step: "+ step) color: #white font: font("Helvetica", 20, #bold) at:{timeLegendPos.x,timeLegendPos.y+40#px,0.01};
	    		
	  	}
	  	graphics "Population"{
	  		point infectiousLegendPos;
	  		if(episode=1){
	  		  infectiousLegendPos<-{world.shape.width*0.5,-300#px};	
	  		}else{
	  		  infectiousLegendPos<-{world.shape.width*1.1,world.shape.height*0.25};	
	  		}
	  		
	  		draw "POPULATION"color: #white at: {infectiousLegendPos.x,infectiousLegendPos.y,0.01}  perspective: true font:font("Helvetica", 30 , #plain);
	  		draw "" + length(people) color: #white at: {infectiousLegendPos.x,infectiousLegendPos.y+30#px,0.01}  perspective: true font:font("Helvetica", 30 , #bold);  
	  	}
	  	
	  	
	  	graphics "Projection"{
	  		float bar_fill;
	  		point infectiousLegendPos;
	  		if(episode=1){
	  		  infectiousLegendPos<-{world.shape.width*0.5,-200#px};	
	  		}else{
	  		  infectiousLegendPos<-{world.shape.width*1.1,world.shape.height*0.5};	
	  		}
	  		point bar_size <- {300#px,10#px};
	  		float x_offset <- 300#px;
	  		float y_offset <- 50#px;
	  		map<string,int> infection_data <- ["Initial infected"::initial_nb_infected, 
	  										   "Low risk"::(ViralPeople count (sum(each.cumulated_viral_load) < Low_Risk_of_Infection_threshold)- initial_nb_infected),
	  										   "Medium risk"::(ViralPeople count (sum(each.cumulated_viral_load) >= Low_Risk_of_Infection_threshold and sum(each.cumulated_viral_load) < Medium_Risk_of_Infection_threshold)),
	  										   "High risk"::(ViralPeople count (sum(each.cumulated_viral_load) >= Medium_Risk_of_Infection_threshold))
	  					];
	  		list<string> risk_colors <- ["blue", "green","orange","red"];
	  		//draw "SIMULATION PROJECTION" color:#white at:{infectiousLegendPos.x,infectiousLegendPos.y-20#px,0.01} perspective: true font:font("Helvetica", 50 , #bold);
			geometry g <- (rectangle(bar_size.x-bar_size.y,bar_size.y) at_location {0,0,0})+(circle(bar_size.y/2) at_location {bar_size.x/2-bar_size.y/2,0})+(circle(bar_size.y/2) at_location {-bar_size.x/2+bar_size.y/2,0});	
			loop i from:0 to: length(infection_data)-1{
				draw infection_data.keys[i] anchor: #left_center color: color_map[risk_colors[i]] at: {infectiousLegendPos.x,infectiousLegendPos.y+i*y_offset,0.01} perspective: true font:font("Helvetica", 20 , #plain); 
	  			draw string(infection_data.values[i])  anchor: #left_center color: color_map[risk_colors[i]] at: {infectiousLegendPos.x,infectiousLegendPos.y+i*y_offset+y_offset/2,0.01} perspective: true font:font("Helvetica", 20 , #bold); 
	  			draw g color: color_map[risk_colors[i]]-140 at: {infectiousLegendPos.x+x_offset,infectiousLegendPos.y+i*y_offset,0.01};
	  			bar_fill <- length(ViralPeople) = 0 ?0:(infection_data.values[i] / length(ViralPeople)*bar_size.x);
	  			geometry g2 <- (g at_location {0,0,0}) inter (g at_location {-bar_size.x+bar_fill,0,0}) ;
	  			draw g2 color: color_map[risk_colors[i]] at: {infectiousLegendPos.x+x_offset-bar_size.x/2+bar_fill/2,infectiousLegendPos.y+i*y_offset,0.011};
			}
	  	}
	  	
	  	graphics "scale"{
	  		float base_scale<-5#m;
	  		if(episode=1){
	  		  base_scale<-3#m;	
	  		}
	  		if(episode=2){
	  		  base_scale<-1#m;	
	  		}
	  		if(episode=3){
	  		  base_scale<-1.5#m;	
	  		}
	  		if(episode=5){
	  			base_scale<-25#m;
	  		}
	  		point scalePos;
	  		if(episode=1){
	  			scalePos<-{world.shape.width*0,-100#px};
	  		}else{
	  			scalePos<-{world.shape.width*1.1,world.shape.height};
	  		}
	  		 
	  		draw "SCALE"color: #white at: {scalePos.x,scalePos.y-30#px,0.01}  perspective: true font:font("Helvetica", 20 , #plain);
	  		
	  		float rectangle_width <- base_scale/6;
	  		list<float> scale_markers <- [0, 1*base_scale, 2*base_scale, 3*base_scale, 5*base_scale];
	  		int side <- 1;
	  		loop i from: 0 to: length(scale_markers)-2{
	  			draw rectangle({scalePos.x+scale_markers[i],scalePos.y},{scalePos.x+scale_markers[i+1],scalePos.y-side*rectangle_width})  color:#white;
	 	 		draw string(int(scale_markers[i])) anchor: i=0? #bottom_left: #bottom_center color: #white font: font("Helvetica", 15, #bold) at:{scalePos.x+scale_markers[i],scalePos.y+rectangle_width+16#px,0.01};
				side <- - side;
	  		}	  		
	  		draw string(int(last(scale_markers)))+ "m" anchor: #bottom_right color: #white font: font("Helvetica", 15, #bold) at:{scalePos.x+last(scale_markers),scalePos.y+rectangle_width+16#px,0.01};
	  	} 
		graphics "social_graph" {
			if (social_distance_graph != nil and drawSocialDistanceGraph = true) {
				loop eg over: social_distance_graph.edges {
					geometry edge_geom <- geometry(eg);
					draw curve(edge_geom.points[0],edge_geom.points[1], 0.5, 200, 90) color:#gray;
			}
		  }
		}
	  }
	  
//  	  display "Infection Risk" type: java2D
//	  {
//		chart "Cumulative Infection Risk" type: series size:{0.5,0.5}//y_range:{0,5000}
//		{
//			data "Direct Contact" value: sum(ViralPeople collect each.cumulated_viral_load[0]) color: # orange style: "area";
//			data "Object Infection" value: sum(ViralPeople collect each.cumulated_viral_load[0])+ sum(ViralPeople collect each.cumulated_viral_load[1]) color: # red style: "area";
//			data "Air Infection" value: sum(ViralPeople collect each.cumulated_viral_load[0])+ sum(ViralPeople collect each.cumulated_viral_load[1])+sum(ViralPeople collect each.cumulated_viral_load[2]) color: # yellow style: "area";
//		}
//		chart "Direct Infection distribution" type: histogram size:{0.5,0.5} position:{0.5,0.0}{
//			data ("") value: (ViralPeople sort_by each.cumulated_viral_load[0] collect each.cumulated_viral_load[0]) color:#orange;
//		}
//		chart "Object Infection distribution" type: histogram size:{0.5,0.5} position:{0.0,0.5}{
//			data ("") value: (ViralPeople sort_by each.cumulated_viral_load[1] collect each.cumulated_viral_load[1]) color:#red;
//		}
//		chart "Air Infection distribution" type: histogram size:{0.5,0.5} position:{0.5,0.5}{
//			data ("") value: (ViralPeople sort_by each.cumulated_viral_load[2] collect each.cumulated_viral_load[2]) color:#yellow;
//		}
//
//	  }
	  display "Infection Risk" type: java2D background:#black
	  {
		chart "Cumulative Infection Risk" type: series color:#white background:#black //y_range:{0,5000}
		{
			data "Direct Contact" value: sum(ViralPeople collect each.cumulated_viral_load[0])/length(ViralPeople) color: # orange style: "area";
			data "Object Infection" value: sum(ViralPeople collect each.cumulated_viral_load[0])/length(ViralPeople)+ sum(ViralPeople collect each.cumulated_viral_load[1])/length(ViralPeople) color: # red style: "area";
			data "Air Infection" value: sum(ViralPeople collect each.cumulated_viral_load[0])/length(ViralPeople)+ sum(ViralPeople collect each.cumulated_viral_load[1])/length(ViralPeople)+sum(ViralPeople collect each.cumulated_viral_load[2])/length(ViralPeople) color: # yellow style: "area";
		}
	  }
	}	
}

