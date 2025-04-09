If you run into Dependencies or Main.tscn error please see the below:
Due to Git having uncompressing issues when it comes to .fbx files that are larger then 1kb, it will not properly load in when you import the project into Godot.
What you will have to manually reimport the Terrain_and_Model file into the FileSystem. 
For example, unzip the project, open File Explorer, navigate to war-of-heroes folder. Then in a seperate window, open the zipped project and drag the Terrain_and_Model into the first window that has the unzaip project.
Replace the folder and then run the project in Godot again. The project should reimport the folder correctly. 

If this does not work from the gradescope downloaded files, please instead download the game using the GitHub Desktop app as it uncompresses the files correctly on there.
If there are still issues regarding dependings or the main.tscn please email us and we will help resolve it. Any Errors/warnings found in the Godot Debugger when first loading the project can be ignored.
