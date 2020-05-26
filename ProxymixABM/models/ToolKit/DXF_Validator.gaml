/**
* Name: DXF to Agents Model
* Author:  Arnaud Grignard
* Description: Model which shows how to create agents by importing data of a DXF file
* Tags:  dxf, load_file
*/
model DXFAgents

import "DXF_Loader.gaml"
global
{

}


experiment ValidatedDXF type: gui
{   
	init
	{   
        create simulation with: [fileName::"MediaLab/ML_3"];
		create simulation with: [fileName::"Grand-Hotel-Dieu_Lyon"];
		create simulation with: [fileName::"ENSAL"];
		create simulation with: [fileName::"Learning_Center_Lyon"];
	}
	parameter 'fileName:' var: fileName category: 'file' <- "Standard_Factory_Gama" among: ["Standard_Factory_Gama", "MediaLab/ML_3","Grand-Hotel-Dieu_Lyon","ENSAL", "Learning_Center_Lyon"];
	output
	{	layout #split;
		display map type: opengl
		{
			species dxf_element;
		}
	}
}

experiment WorkInProgressDXF type: gui
{   
	init
	{   
	}
	parameter 'fileName:' var: fileName category: 'file' <- "Learning_Center_Lyon" among: ["Learning_Center_Lyon"];
	output
	{	layout #split;
		display map type: opengl
		{
			species dxf_element;
		}
	}
}