require "java"
require "libraries/weka.jar"
require "libraries/conversorWeka2Keel.jar"

java_import "weka.associations.Apriori"

java_import "weka.core.Instances"
java_import "java.io.BufferedReader"
java_import "java.io.FileReader"
java_import "java.lang.System"

java_import "conversor.WekaToKeel"

# Clase usada para contener los diferentes algoritmos
class Algorithms
	def self.queue
    	:queries
  	end

  	def self.perform(query_id)
  		puts 'Query: ' + query_id.to_s
  		query = Query.find(query_id)
  		puts 'Inicia algoritmo: ' + query.algorithm
  		query.status = 1
  		puts 'Estado: ' + query.status
  		query.save
  		sleep(10)
  		query.result = aplicar(query.queryfile.current_path.to_s, query.algorithm)
  		puts 'Finaliza un algoritmo'
  		query.status = 2
  		puts 'Estado: ' + query.status
  		query.save
  	end

	# Aplica un algoritmo a un archivo y devuelve la ubicación del fichero resultado
	def self.aplicar(file, algorithm)
		# Aplicar SD (En un futuro, añadir a lista de espera para SD)
		case algorithm
			when "apriori"
				toRet = apriori(file)
				return toRet
			when "cn2"
				toRet = cn2sd(file)
				return toRet
			when "mesdif"
				toRet = mesdif(file)
				return toRet
		end
	end

	# Comprueba si hay que convertir el archivo a Keel, devolviendo la ubicación final del archivo en un string
	def self.conversorKeel(file)
		# Comprobación previa del fichero para realizar conversión o no
		
	  	case File.extname(file)
	  	
	  	when ".arff"
	  		# Convertir a .dat de Keel
	  		fileTrans = WekaToKeel.new();
	  		fileInput = file
	  		fileOutput = File.dirname(file) + "/" + File.basename(file, ".*").downcase + ".dat"
	        fileTrans.Start(fileInput, fileOutput)
	  	when ".dat"
	  		# no hacer nada
	  		fileOutput = file
	  	end

	  	return fileOutput
	end

	# Función Apriori, aplica el alogirtmo apriori de Weka
	  def self.apriori(file)
	  	# Se leen los datos
		reader = BufferedReader.new(FileReader.new(file))
        data = Instances.new(reader)
        reader.close()

		# Algoritmo Apriori
		_model = Apriori.new()
		
		# Se construye el modelo
		_model.buildAssociations(data)

		# Obtenemos el resultado
		toRet = _model.toString()

		return toRet

	  end

	  # Función CN2, aplica el algoritmo CN2-SD de Keel
	  def self.cn2sd(file)
	  	#sleep(5)

	  	# Comprobamos si hay que convertirlo, devolviendo un string con la ubicación final
	  	convertedInput = conversorKeel(file)

	  	# Se definen los parámetros del algoritmo
	  	algorithm = "algorithm = CN2 Algorithm for Subgroup Discovery\n"
	  	#inputData = "inputData = " + "\"" + file.current_path + "\" " + "\"" + file.current_path + "\" " +"\"" + file.current_path + "\"\n"
	  	inputData = "inputData = " + "\"" + convertedInput + "\" " + "\"" + convertedInput + "\" " +"\"" + convertedInput + "\"\n"
        output = File.dirname(file) + "/result"
        outputData = "outputData = " + "\"" + output + ".tra\" " + "\"" + output + ".tst\" " + "\"" + output + ".txt\"\n"
        
        nu_value = "Nu_Value = 0.5\n"
        percentage = "Percentage_Examples_To_Cover = 0.95\n"
        star_size = "Star_Size = 5\n"
        multiplicative = "Use_multiplicative_weights = YES\n"
        disjunt = "Use_Disjunt_Selectors = NO"


        # Preparar el archivo de configuración
        configuracion = File.dirname(file) + "/configuracionCN2.txt"

        config_file = open(configuracion, "w")

        config_file.write(algorithm)
        config_file.write(inputData)
        config_file.write(outputData)
        config_file.write("\n")
        config_file.write(nu_value)
        config_file.write(percentage)
        config_file.write(star_size)
        config_file.write(multiplicative)
        config_file.write(disjunt)

        config_file.close

        # Ejecutar el comando para aplicar el algoritmo
        comando = "java -jar /home/david/proyectojruby/app/controllers/libraries/CN2SD.jar " + configuracion

        ejecucion = system( comando )

        if ejecucion == true
        	toRet = output + ".txt"
        else
        	toRet = "error"
        end

        return toRet
	  end

	  # Función MESDIF, aplica el algoritmo MESDIF-SD de Keel
	  def self.mesdif(file)
	  	#sleep(5)

	  	# Comprobamos si hay que convertirlo, devolviendo un string con la ubicación final
	  	convertedInput = conversorKeel(file)

	  	# Se definen los parámetros del algoritmo
	  	algorithm = "algorithm = MESDIF for Subgroup Discovery\n"
	  	inputData = "inputData = " + "\"" + convertedInput + "\" " + "\"" + convertedInput + "\" " +"\"" + convertedInput + "\"\n"
        output = File.dirname(file) + "/result"
        outputData = "outputData = " + "\"" + output + "0.tra\" " + "\"" + output + "0.tst\" " + "\"" + output + "0e0.txt\" " + 
        							   "\"" + output + "0e1.txt\" " + "\"" + output + "0e2.txt\" " + "\"" + output + "0e3.txt\"\n"
        
        rulesRep = "RulesRep = can\n"
		nLabels = "nLabels = 3\n"
		nEval = "nEval = 10000\n"
		popLength = "popLength = 100\n"
		crossProb = "crossProb = 0.6\n"
		mutProb = "mutProb = 0.01\n"
		eliteLength = "eliteLength = 3\n"
		obj1 = "Obj1 = comp\n"
		obj2 = "Obj2 = unus\n"
		obj3 = "Obj3 = fcnf\n"
		obj4 = "Obj4 = null\n"


        # Preparar el archivo de configuración
        configuracion = File.dirname(file) + "/configuracionMESDIF.txt"

        config_file = open(configuracion, "w")

        config_file.write(algorithm)
        config_file.write(inputData)
        config_file.write(outputData)
        config_file.write("\n")
        config_file.write(rulesRep)
        config_file.write(nLabels)
        config_file.write(nEval)
        config_file.write(popLength)
        config_file.write(crossProb)
        config_file.write(mutProb)
        config_file.write(eliteLength)
        config_file.write(obj1)
        config_file.write(obj2)
        config_file.write(obj3)
        config_file.write(obj4)

        config_file.close

        # Ejecutar el comando para aplicar el algoritmo
        comando = "java -jar /home/david/proyectojruby/app/controllers/libraries/MESDIF.jar " + configuracion

        ejecucion = system( comando )

        if ejecucion == true
        	toRet = output + "0e0.txt"
        else
        	toRet = "error"
        end

        return toRet
	  end
end

class QueriesController < ApplicationController
	before_action :logged_in_user, only: [:create, :destroy, :list, :new]

	def create
		@user = current_user
		@query = @user.queries.build(query_params)

		if @query.save
			flash[:success] = "Nueva consulta creada con éxito"

			# Añade la consulta a la cola de espera y pasa el id para actualizarla al acabar
			Resque.enqueue(Algorithms, @query.id)

			redirect_to queries_path
		else
	  		render 'new'
	  	end
	end

	def destroy	
		# Se borra también la carpeta y archivos relacionados
		query = Query.find(params[:id])
		direccion = File.dirname(query.queryfile.current_path.to_s)

		query.destroy
		FileUtils.rm_rf(direccion)
		
		flash[:success] = "Consulta eliminada"
		redirect_to request.referrer
	end

	def new
	  	@query = Query.new
	 end

	def list
		@user = current_user
		@queries = @user.queries
	end

	def show
		@query = Query.find(params[:id])
		if @query.result?
			@resultado = @query.result
		end
	end

	private

	  def query_params
	  	params.require(:query).permit(:description, :queryfile, :algorithm)
	  end

end
